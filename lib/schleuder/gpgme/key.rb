module GPGME
  class Key
    # Overwrite to specify the full fingerprint instead of the short key-ID.
    def to_s
      primary_subkey = subkeys[0]
      s = sprintf("%s   %4d%s/%s %s\n",
                  primary_subkey.secret? ? 'sec' : 'pub',
                  primary_subkey.length,
                  primary_subkey.pubkey_algo_letter,
                  primary_subkey.fingerprint,
                  primary_subkey.timestamp.strftime('%Y-%m-%d'))
      uids.each do |user_id|
        s << "uid\t\t#{user_id.name} <#{user_id.email}>\n"
      end
      subkeys.each do |subkey|
        s << subkey.to_s
      end
      s
    end

    def generated_at
      primary_subkey.timestamp
    end

    def expired?
      expired.present?
    end

    def summary
      @summary ||= 
        begin
          datefmt = '%Y-%m-%d'
          attribs = [
            "0x#{fingerprint}",
            email,
            generated_at.strftime(datefmt)
          ]
          if usability_issue.present?
            case usability_issue
            when :expired
              attribs << "[expired: #{expires.strftime(datefmt)}]"
            when :revoked
              # TODO: add revocation date when it's available.
              attribs << '[revoked]'
            else
              attribs << "[#{usability_issue}]"
            end
          end
          if expires? && ! expired?
            attribs << "[expires: #{expires.strftime(datefmt)}]"
          end
          attribs.join(' ')
        end
    end

    def armored
      "#{self.to_s}\n\n#{export(armor: true).read}"
    end

    def minimal
      export(minimal: true).to_s
    end

    # Force encoding, some databases save "ASCII-8BIT" as binary data.
    alias_method :orig_fingerprint, :fingerprint
    def fingerprint
      orig_fingerprint.encode(Encoding::US_ASCII)
    end

    def usable?
      usability_issue.blank?
    end

    def usability_issue
      if trust.present?
        trust
      elsif ! usable_for?(:encrypt)
        'not capable of encryption'
      else
        nil
      end
    end

    def self.valid_fingerprint?(fp)
      fp =~ Schleuder::Conf::FINGERPRINT_REGEXP
    end
  end
end
