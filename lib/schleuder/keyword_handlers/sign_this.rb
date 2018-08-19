module Schleuder
  module KeywordHandlers
    class SignThis < Base
      handles_request_keyword 'sign-this', with_method: :sign_this

      def sign_this
        if @mail.has_attachments?
          @list.logger.debug "Signing each attachment's body"
          intro = I18n.t('keyword_handlers.sign_this.signatures_attached')
          parts = @mail.attachments.map do |attachment|
            make_signature_part(attachment)
          end
          [intro, parts].flatten
        elsif @mail.first_plaintext_part.body.to_s.present?
          @list.logger.debug 'Clear-signing first available text/plain part'
          clearsign(@mail.first_plaintext_part.body.to_s)
        else
          @list.logger.debug 'Found no attachments and an empty body - sending error message'
          I18n.t('keyword_handlers.sign_this.no_content_found')
        end
      end


      private


      def make_signature_part(attachment)
        material = attachment.body.to_s
        return nil if material.strip.blank?
        file_basename = attachment.filename.presence || Digest::SHA256.hexdigest(material)
        @list.logger.debug "Signing #{file_basename}"
        filename = "#{file_basename}.sig"
        part = Mail::Part.new
        part.body = detachsign(material)
        part.content_type = 'application/pgp-signature'
        part.content_disposition = "attachment; filename=#{filename}"
        part.content_description = "OpenPGP signature for '#{file_basename}'"
        part
      end

      def detachsign(thing)
        crypto.sign(thing, mode: GPGME::SIG_MODE_DETACH).to_s
      end

      def clearsign(string)
        crypto.clearsign(string.to_s).to_s
      end

      def crypto
        @crypto ||= GPGME::Crypto.new(armor: true)
      end
    end
  end
end
