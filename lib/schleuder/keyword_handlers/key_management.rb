module Schleuder
  module KeywordHandlers
    class KeyManagement < Base
      handles_request_keyword 'add-key', with_method: 'add_key'
      handles_request_keyword 'delete-key', with_method: 'delete_key'
      handles_request_keyword 'list-keys', with_method: 'list_keys', has_aliases: 'list-key'
      handles_request_keyword 'get-key', with_method: 'get_key', has_aliases: 'get-keys'
      handles_request_keyword 'fetch-key', with_method: 'fetch_key', has_aliases: 'fetch-keys'
      
      def add_key
        results = 
          if @mail.has_attachments?
            import_keys_from_attachments
          elsif @mail.first_plaintext_part.body.to_s.present?
            import_key_from_body
          else
            @list.logger.debug 'Found no attachments and an empty body - sending error message'
            I18n.t('keyword_handlers.key_management.no_content_found')
          end

        import_stati = results.compact.collect(&:imports).flatten

        if import_stati.blank?
          return I18n.t('keyword_handlers.key_management.no_imports')
        end

        out = []

        import_stati.each do |import_status|
          if import_status.action == 'error'
            out << I18n.t('keyword_handlers.key_management.key_import_status.error', fingerprint: import_status.fingerprint)
          else
            key = @list.gpg.find_distinct_key(import_status.fingerprint)
            if key
              out << I18n.t("keyword_handlers.key_management.key_import_status.#{import_status.action}", key_oneline: key.oneline)
            end
          end
        end

        out.join("\n\n")
      end

      def delete_key
        if @arguments.blank?
          return I18n.t(
            'keyword_handlers.key_management.delete_key_requires_arguments'
          )
        end

        @arguments.map do |argument|
          keys = @list.keys(argument)
          case keys.size
          when 0
            I18n.t('errors.no_match_for', input: argument)
          when 1
            begin
              keys.first.delete!
              I18n.t('keyword_handlers.key_management.deleted', key_string: keys.first.oneline)
            rescue GPGME::Error::Conflict
              I18n.t('keyword_handlers.key_management.not_deletable', key_string: keys.first.oneline)
            end
          else
            I18n.t('errors.too_many_matching_keys', {
                input: argument,
                key_strings: keys.map(&:to_s).join("\n")
              })
          end
        end.join("\n\n")
      end

      def list_keys
        args = Array(@arguments.presence || '')
        args.map do |argument|
          # In this case it shall be allowed to match keys by arbitrary
          # sub-strings, therefore we use `list.gpg` directly to not have the
          # input filtered.
          @list.gpg.keys(argument).map do |key|
            key.to_s
          end
        end.join("\n\n")
      end

      def get_key
        @arguments.map do |argument|
          keys = @list.keys(argument)
          if keys.blank?
            I18n.t('errors.no_match_for', input: argument)
          else
            result = [I18n.t('keyword_handlers.key_management.matching_keys_intro', input: argument)]
            keys.each do |key|
              atchm = Mail::Part.new
              atchm.body = key.armored
              atchm.content_type = 'application/pgp-keys'
              atchm.content_disposition = "attachment; filename=#{key.fingerprint}.asc"
              result << atchm
            end
            result.flatten
          end
        end
      end

      def fetch_key
        if @arguments.blank?
          return I18n.t(
            'keyword_handlers.key_management.fetch_key_requires_arguments'
          )
        end

        @arguments.map do |argument|
          @list.fetch_keys(argument)
        end
      end


      private


      def import_keys_from_attachments
        @mail.attachments.map do |attachment|
          import_from_string(attachment.body.to_s)
        end
      end

      def import_key_from_body
        [import_from_string(@mail.first_plaintext_part.body.to_s)]
      end

      def import_from_string(string)
        @list.import_key(string)
      end
    end
  end
end
