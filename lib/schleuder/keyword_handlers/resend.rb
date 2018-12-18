module Schleuder
  module KeywordHandlers
    class Resend < Base
      handles_list_keyword 'resend-encrypted-only', with_method: :resend_encrypted_only, has_aliases: 'resend-enc'

      handles_list_keyword 'resend', with_method: :resend

      handles_list_keyword 'resend-cc', with_method: :resend_cc

      handles_list_keyword 'resend-cc-encrypted-only', with_method: :resend_cc_encrypted_only, has_aliases: 'resend-cc-enc'

      handles_list_keyword 'resend-unencrypted', with_method: :resend_unencrypted

      handles_list_keyword 'resend-cc-unencrypted', with_method: :resend_cc_unencrypted


      def resend
        resend_it
      end

      def resend_encrypted_only
        resend_it(encrypted_only: true)
      end

      def resend_cc
        resend_it_cc
      end

      def resend_cc_encrypted_only
        resend_it_cc(encrypted_only: true)
      end

      def resend_unencrypted
        do_resend_unencrypted(:to)
      end

      def resend_cc_unencrypted
        do_resend_unencrypted(:cc)
      end


      private


      def do_resend_unencrypted(target)
        if ! resend_recipients_valid?
          return false
        end

        recip_map = Hash[Array(@arguments).map { |email| [email, ''] } ]

        if do_resend(recip_map, target, false)
          mail.add_subject_prefix_out!
        end
      end

      def resend_it_cc(encrypted_only: false)
        if ! resend_recipients_valid?
          return false
        end

        recip_map = map_with_keys(encrypted_only: encrypted_only)

        # Only continue if all recipients are still here.
        if recip_map.size < @arguments.size
          recip_map.keys.each do |aborted_sender|
            @mail.add_pseudoheader(:error, I18n.t("keyword_handlers.resend.aborted", email: aborted_sender))
          end
          return
        end

        if do_resend(recip_map, :cc, encrypted_only)
          @mail.add_subject_prefix_out!
        end
      end

      def resend_it(encrypted_only: false)
        if ! resend_recipients_valid?
          return false
        end

        recip_map = map_with_keys(encrypted_only: encrypted_only)

        resent_stati = recip_map.map do |email, key|
          do_resend({email => key}, :to, encrypted_only)
        end

        if resent_stati.include?(true)
          # At least one message has been resent
          @mail.add_subject_prefix_out!
        end
      end

      def do_resend(recipients_map, to_or_cc, encrypted_only)
        if recipients_map.empty?
          return
        end

        gpg_opts = make_gpg_opts(recipients_map, encrypted_only)
        if gpg_opts == false
          return false
        end

        # Compose and send email
        new = @mail.clean_copy
        new[to_or_cc] = recipients_map.keys
        new.add_public_footer!
        new.sender = @list.bounce_address
        # `dup` gpg_opts because `deliver` changes their value and we need them
        # below to determine encryption!
        new.gpg gpg_opts.dup

        if new.deliver
          add_resent_headers(recipients_map, to_or_cc, gpg_opts[:encrypt])
          return true
        else
          add_error_header(recipients_map)
          return false
        end
      rescue Net::SMTPFatalError => exc
        add_error_header(recipients_map)
        logger.error "Error while sending: #{exc}"
        return false
      end

      def map_with_keys(encrypted_only:)
        Array(@arguments).inject({}) do |hash, email|
          keys = @list.keys(email)
          # Exclude unusable keys.
          usable_keys = keys.select { |key| key.usable_for?(:encrypt) }
          case usable_keys.size
          when 1
            hash[email] = usable_keys.first
          when 0
            if encrypted_only
              # Don't add the email to the result to exclude it from the
              # recipients.
              add_resend_msg(email, :error, 'not_resent_no_keys', usable_keys.size, keys.size)
            else
              hash[email] = ''
            end
          else
            # Always report this situation, regardless of sending or not. It's
            # bad and should be fixed.
            add_resend_msg(email, :notice, 'not_resent_encrypted_no_keys', usable_keys.size, keys.size)
            if ! encrypted_only
              hash[email] = ''
            end
          end
          hash
        end
      end

      def make_gpg_opts(recipients_map, encrypted_only)
        gpg_opts = @list.gpg_sign_options
        # Do all recipients have a key?
        if recipients_map.values.map(&:class).uniq == [GPGME::Key]
          gpg_opts.merge!(encrypt: true)
        elsif encrypted_only
          false
        end
        gpg_opts
      end

      def add_resend_msg(email, severity, msg, usable_keys_size, all_keys_size)
        @mail.add_pseudoheader(severity, I18n.t("keyword_handlers.resend.#{msg}", email: email, usable_keys: usable_keys_size, all_keys: all_keys_size))
      end

      def add_error_header(recipients_map)
        @mail.add_pseudoheader(:error, "Resending to #{recipients_map.keys.join(', ')} failed, please check the logs!")
      end

      def add_resent_headers(recipients_map, to_or_cc, sent_encrypted)
        if sent_encrypted
          prefix = I18n.t('keyword_handlers.resend.encrypted_to')
          str = "\n" + recipients_map.map do |email, key|
            "#{email} (#{key.fingerprint})"
          end.join(",\n")
        else
          prefix = I18n.t('keyword_handlers.resend.unencrypted_to')
          str = ' ' + recipients_map.keys.join(', ')
        end
        headername = resent_header_name(to_or_cc)
        @mail.add_pseudoheader(headername, "#{prefix}#{str}")
      end

      def resent_header_name(to_or_cc)
        if to_or_cc.to_s == 'to'
          'resent'
        else
          'resent_cc'
        end
      end

      def resend_recipients_valid?
        all_valid = true
        Array(@arguments).each do |address|
          if ! address.match(Conf::EMAIL_REGEXP)
            mail.add_pseudoheader(:error, I18n.t('keyword_handlers.resend.invalid_recipient', address: address))
            all_valid = false
          end
        end
        all_valid
      end

    end
  end
end
