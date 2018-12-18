module Schleuder
  module KeywordHandlers
    class AttachListKey < Base
      handles_list_keyword 'attach-listkey', with_method: :attach_list_key

      def attach_list_key
        new_part = Mail::Part.new
        new_part.body = @list.export_key
        new_part.content_type = 'application/pgp-keys'
        new_part.content_description = "OpenPGP public key of #{@list.email}"
        new_part.content_disposition = "attachment; filename=#{@list.fingerprint}.pgpkey"
        @mail.add_part new_part
        nil
      end
    end
  end
end
