module GPGME
  class Ctx
    IMPORT_FLAGS = {
      'new_key' => 1,
      'new_uids' => 2,
      'new_signatures' => 4,
      'new_subkeys' => 8
    }

    def keyimport(keydata)
      self.import_keys(GPGME::Data.new(keydata))
      result = self.import_result
      result.imports.map(&:set_action)
      result
    end

    # TODO: find solution for I18n — could be a different language in API-clients than here!
    def interpret_import_result(import_result)
      case import_result.imports.size
      when 1
        import_status = import_result.imports.first
        if import_status.action == 'error'
          [nil, "Key #{import_status.fpr} could not be imported!"]
        else
          [import_status.fpr, nil]
        end
      when 0
        [nil, "The given key material did not contain any keys!"]
      else
        # TODO: report import-stati of the keys?
        [nil, "The given key material contained more than one key, could not determine which fingerprint to use. Please set it manually!"]
      end
    end

    def find_keys(input=nil, secret_only=nil)
      _, input = clean_and_classify_input(input)
      keys(input, secret_only)
    end

    def find_distinct_key(input=nil, secret_only=nil)
      _, input = clean_and_classify_input(input)
      keys = keys(input, secret_only)
      if keys.size == 1
        keys.first
      else
        nil
      end
    end

    def clean_and_classify_input(input)
      case input
      when /.*?([^ <>]+@[^ <>]+).*?/
        [:email, "<#{$1}>"]
      when /^http/
        [:url, input]
      when Conf::FINGERPRINT_REGEXP
        [:fingerprint, "0x#{input.gsub(/^0x/, '')}"]
      else
        [nil, input]
      end
    end

    # Tell gpgme to use the given binary.
    def self.set_gpg_path_from_env
      path = ENV['GPGBIN'].to_s
      if ! path.empty?
        Schleuder.logger.debug "setting gpg to use #{path}"
        GPGME::Engine.set_info(GPGME::PROTOCOL_OpenPGP, path, ENV['GNUPGHOME'])
        if gpg_engine.version.nil?
          $stderr.puts "Error: The binary you specified doesn't provide a gpg-version."
          exit 1
        end
      end
    end

    def self.sufficient_gpg_version?(required)
      Gem::Version.new(required) <= Gem::Version.new(gpg_engine.version)
    end

    def self.check_gpg_version
      if ! sufficient_gpg_version?('2.2')
        $stderr.puts "Error: GnuPG version >= 2.2 required.\nPlease install it and/or provide the path to the binary via the environment-variable GPGBIN.\nExample: GPGBIN=/opt/gpg2/bin/gpg ..."
        exit 1
      end
    end

    def self.gpg_engine
      GPGME::Engine.info.find {|e| e.protocol == GPGME::PROTOCOL_OpenPGP }
    end

    def refresh_keys(keys)
      # reorder keys so the update pattern is random
      output = keys.shuffle.map do |key|
        # Sleep a short while to make traffic analysis less easy.
        sleep rand(1.0..5.0)
        refresh_key(key.fingerprint).presence
      end
      `gpgconf --kill dirmngr`
      output.compact.join("\n")
    end

    def refresh_key(fingerprint)
      args = "#{keyserver_arg} #{import_filter_arg} --refresh-keys #{fingerprint}"
      gpgerr, gpgout, exitcode = self.class.gpgcli(args)

      if exitcode > 0
        # Return filtered error messages. Include gpgkeys-messages from stdout
        # (gpg 2.0 does that), which could e.g. report a failure to connect to
        # the keyserver.
        # TODO: Revisit this once we don't do network access via GPG
        # anymore.
        res = [
          refresh_key_filter_messages(gpgerr),
          refresh_key_filter_messages(gpgout).grep(/^gpgkeys: /)
        ].flatten.compact
        # if there was an error that we don't filter out,
        # we better kill dirmngr, so it hopefully won't suffer
        # from the same error during the next run.
        # See #309 for background
        if !res.empty?
          `gpgconf --kill dirmngr`
        end
        res.join("\n")
      else
        lines = translate_output('key_updated', gpgout).reject do |line|
          # Reduce the noise a little.
          line.match(/.* \(unchanged\):$/)
        end
        lines.join("\n")
      end
    end

    def fetch_key(input)
      arguments, error = fetch_key_gpg_arguments_for(input)
      return error if error

      self.class.send_notice_if_gpg_does_not_know_import_filter
      gpgerr, gpgout, exitcode = self.class.gpgcli("#{import_filter_arg} #{arguments}")

      # Unfortunately gpg doesn't exit with code > 0 if `--fetch-key` fails.
      if exitcode > 0 || gpgerr.grep(/ unable to fetch /).presence
        "Fetching #{input} did not succeed:\n#{gpgerr.join("\n")}"
      else
        translate_output('key_fetched', gpgout).join("\n")
      end
    end

    def fetch_key_gpg_arguments_for(input)
      case input
      when Conf::FINGERPRINT_REGEXP
        "#{keyserver_arg} --recv-key #{input}"
      when /^http/
        "--fetch-key #{input}"
      when /@/
        # --recv-key doesn't work with email-addresses, so we use --locate-key
        # restricted to keyservers.
        "#{keyserver_arg} --auto-key-locate keyserver --locate-key #{input}"
      else
        [nil, I18n.t("fetch_key.invalid_input")]
      end
    end

    def translate_output(locale_key, gpgoutput)
      import_states = translate_import_data(gpgoutput)
      strings = import_states.map do |fingerprint, states|
        key = find_distinct_key(fingerprint)
        I18n.t(locale_key, { key_oneline: key.oneline,
                             states: states.to_sentence })
      end
      strings
    end

    def translate_import_data(gpgoutput)
      result = {}
      gpgoutput.grep(/IMPORT_OK/) do |import_ok|
        next if import_ok.blank?

        import_status, fingerprint = import_ok.split(/\s/).slice(2, 2)
        import_status = import_status.to_i
        states = []

        if import_status == 0
          states << I18n.t("import_states.unchanged")
        else
          IMPORT_FLAGS.each do |text, int|
            if (import_status & int) > 0
              states << I18n.t("import_states.#{text}")
            end
          end
        end
        result[fingerprint] = states
      end
      result
    end

    # Unfortunately we can't distinguish between a failure to connect the
    # keyserver, and a failure to find the key on the server. So we try to
    # filter misleading errors to check if there are any to be reported.
    def refresh_key_filter_messages(strings)
      strings.reject do |line|
        line.chomp == 'gpg: keyserver refresh failed: No data' ||
          line.match(/^gpgkeys: key .* not found on keyserver/) ||
          line.match(/^gpg: refreshing /) ||
          line.match(/^gpg: requesting key /) ||
          line.match(/^gpg: no valid OpenPGP data found/)
      end
    end

    def self.gpgcli(args)
      exitcode = -1
      errors = []
      output = []
      base_cmd = gpg_engine.file_name
      base_args = "--no-greeting --no-permission-warning --quiet --armor --trust-model always --no-tty --command-fd 0 --status-fd 1"
      cmd = [base_cmd, base_args, args].flatten.join(' ')
      Open3.popen3(cmd) do |stdin, stdout, stderr, thread|
        if block_given?
          output = yield(stdin, stdout, stderr)
        else
          output = stdout.readlines
        end
        stdin.close if ! stdin.closed?
        errors = stderr.readlines
        exitcode = thread.value.exitstatus
      end

      [errors, output, exitcode]
    rescue Errno::ENOENT
      raise 'Need gpg in $PATH or in $GPGBIN'
    end

    def self.gpgcli_expect(args)
      gpgcli(args) do |stdin, stdout, stderr|
        counter = 0
        while line = stdout.gets rescue nil
          counter += 1
          if counter > 1042
            return "Too many input-lines from gpg, something went wrong"
          end
          output, error = yield(line.chomp)
          if output == false
            return error
          elsif output
            stdin.puts output
          end
        end
      end
    end

    def self.spawn_daemon(name, args)
      delete_daemon_socket(name)
      cmd = "#{name} #{args} --daemon > /dev/null 2>&1"
      if ! system(cmd)
        return [false, "#{name} exited with code #{$?}"]
      end
    end

    def self.delete_daemon_socket(name)
      path = File.join(ENV["GNUPGHOME"], "S.#{name}")
      if File.exist?(path)
        File.delete(path)
      end
    end

    def keyserver_arg
      if Conf.keyserver.present?
        "--keyserver #{Conf.keyserver}"
      else
        ""
      end
    end

    def self.gpg_knows_import_filter?
      sufficient_gpg_version?('2.1.15')
    end

    def import_filter_arg
      if self.class.gpg_knows_import_filter?
        %{ --import-filter drop-sig='sig_created_d > 0000-00-00'}
      end
    end

    def self.send_notice_if_gpg_does_not_know_import_filter
      if ! gpg_knows_import_filter?
        Schleuder.logger.notify_superadmin(
            subject: 'Schleuder installation problem',
            message: "Your version of GnuPG is very old, please update!\n\nWith your version of GnuPG we can not protect your setup against signature flooding. Please update to at least version 2.1.15 to fix this problem. See <https://dkg.fifthhorseman.net/blog/openpgp-certificate-flooding.html> for details on the background."
          )
        ''
      end
    end
  end
end
