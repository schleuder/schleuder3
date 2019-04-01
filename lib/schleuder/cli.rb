require 'thor'
require 'yaml'
require 'gpgme'
require 'charlock_holmes'

require_relative '../schleuder'
require 'schleuder/cli/subcommand_fix'
require 'schleuder/cli/cli_helper'
require 'schleuder/cli/schleuder_cert_manager'
require 'schleuder/cli/cert'

module Schleuder
  class Cli < Thor
    include CliHelper

    register(Cert,
             'cert',
             'cert ...',
             'Generate TLS-certificate and show fingerprint')

    map '-v' => :version
    map '--version' => :version
    desc 'version', 'Show version of schleuder'
    def version
      say Schleuder::VERSION
    end

    desc 'new_api_key', 'Generate a new API key to be used by a client.'
    def new_api_key
      require 'securerandom'
      puts SecureRandom.hex(32)
    end

    desc 'work list@hostname < message', 'Run a message through a list.'
    def work(listname)
      message  = STDIN.read

      error = Schleuder::Runner.new.run(message, listname)
      if error.kind_of?(StandardError)
        fatal error
      end
    rescue => exc
      begin
        Schleuder.logger.fatal(exc.message_with_backtrace, message)
        # Don't use FatalError here to reduce dependency on other code.
        say I18n.t('errors.fatalerror')
      rescue => e
        # Give users a clue what to do in case everything blows up.
        # As apparently even the logging raised exceptions we can't even store
        # any information in the logs.
        fatal "A serious, unhandleable error happened. Please contact the administrators of this system or service and provide them with the following information:\n\n#{e.message}"
      end
      exit 1
    end

    desc 'check_keys', 'Check all lists for unusable or expiring keys and send the results to the list-admins. (This is supposed to be run from cron or systemd weekly.)'
    def check_keys
      List.all.each do |list|
        I18n.locale = list.language

        text = list.check_keys

        if text && ! text.empty?
          msg = "#{I18n.t('check_keys_intro', email: list.email)}\n\n#{text}"
          list.logger.notify_admin(msg, nil, I18n.t('check_keys'))
        end
      end
      permission_notice
    end

    desc 'refresh_keys [list1@example.com]', 'Refresh all keys of all list from the keyservers sequentially (one by one or on the passed list). (This is supposed to be run from cron or systemd weekly.)'
    def refresh_keys(list=nil)
      GPGME::Ctx.send_notice_if_gpg_does_not_know_import_filter
      work_on_lists(:refresh_keys,list)
      permission_notice
    end


    desc 'install', 'Set-up or update Schleuder environment (create folders, copy files, fill the database).'
    def install
      config_dir = Pathname.new(ENV['SCHLEUDER_CONFIG']).dirname
      root_dir = Pathname.new(ENV['SCHLEUDER_ROOT'])

      # Check if lists_dir contains v2-data.
      if Dir.glob("#{Conf.lists_dir}/*/*/members.conf").size > 0
        msg = "Lists directory #{Conf.lists_dir} appears to contain data from a Schleuder version 2.x installation.\nPlease move it out of the way or configure a different `lists_dir` in `#{ENV['SCHLEUDER_CONFIG']}`.\nTo migrate lists from Schleuder v2 to Schleuder v3 please use `schleuder migrate_v2_list` after the installation succeeded."
        fatal msg, 2
      end

      [Conf.keyword_handlers_dir, Conf.lists_dir, Conf.listlogs_dir, config_dir].each do |dir|
        dir = Pathname.new(dir)
        if ! dir.exist?
          begin
            dir.mkpath
          rescue Errno::EACCES => exc
            problem_dir = exc.message.split(' - ').last
            fatal "Cannot create required directory due to lacking write permissions: #{problem_dir}.\nPlease fix the permissions or create the directory manually and then run this command again."
          end
        end
      end

      Pathname.glob(root_dir.join("etc").join("*.yml")).each do |file|
        target = config_dir.join(file.basename)
        if ! target.exist?
          if target.dirname.writable?
            FileUtils.cp file, target
          else
            fatal "Cannot copy default config file due to lacking write permissions, please copy manually and then run this command again:\n#{file.realpath} → #{target}"
          end
        end
      end

      if ActiveRecord::SchemaMigration.table_exists?
        say shellexec("cd #{root_dir} && rake db:migrate")
      else
        say shellexec("cd #{root_dir} && rake db:init")
        if Conf.database['adapter'].match(/sqlite/)
          say "NOTE: The database was prepared using sqlite. If you prefer to use a different DBMS please edit the 'database'-section in /etc/schleuder/schleuder.yml, create the database, install the corresponding ruby-library (e.g. `gem install mysql`) and run this current command again"
        end
      end

      if ! File.exist?(Conf.api['tls_cert_file']) || ! File.exist?(Conf.api['tls_key_file'])
        Schleuder::Cert.new.generate
      end

      say "Schleuder has been set up. You can now create a new list using `schleuder-cli`.\nWe hope you enjoy!"
      permission_notice
    rescue => exc
      fatal exc.message
    end

    no_commands do
      def shellexec(cmd)
        result = `#{cmd} 2>&1`
        if $?.exitstatus > 0
          exit $?.exitstatus
        end
        result
      end
    end

    private

    def work_on_lists(subj, list=nil)
      if list.nil?
        selected_lists = List.all
      else
        selected_lists = List.where(email: list)
        if selected_lists.blank?
          error("No list with this address exists: #{list.inspect}")
        end
      end

      selected_lists.each do |list|
        I18n.locale = list.language
        output = list.send(subj)
        if output.present?
          msg = "#{I18n.t("#{subj}_intro", email: list.email)}\n\n#{output}"
          list.logger.notify_admin(msg, nil, I18n.t(subj))
        end
      end
    end

    # Make this class exit with code 1 in case of an error. See <https://github.com/erikhuda/thor/issues/244>.
    def self.exit_on_failure?
      true
    end

    def permission_notice
      if Process.euid == 0
        dirs = [Conf.lists_dir, Conf.listlogs_dir]
        if Conf.database['adapter'] == 'sqlite3'
          dirs << Conf.database['database']
        end
        dirs_sentence = dirs.uniq.map { |dir| enquote(dir) }.to_sentence
        say "Warning: this process was run as root -- please make sure that all files in #{dirs_sentence} have correct file system permissions for the user that is running both, schleuder from the MTA and `schleuder-api-daemon`."
      end
    end

    def enquote(string)
      "\`#{string}\`"
    end

  end
end
