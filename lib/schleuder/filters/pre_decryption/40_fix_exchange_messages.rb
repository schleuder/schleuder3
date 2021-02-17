module Schleuder
  module Filters

    # Outlook / Hotmail seems to dismantle multipart/encrypted messages and
    # put them again together as multipart/mixed, which is wrong and makes
    # it problematic to correctly detect the message as a valid pgp/mime-mail.
    # Here we fix the mail to be a proper pgp/mime aka. multipart/encrypted
    # message, so further processing will detect it properly.
    # This problem seems to be in fact related to the use of Microsoft
    # Exchange. Accordingly, check if the headers contain 'X-MS-Exchange'.
    # See #211, #246, #331 and #333 for background.
    def self.fix_exchange_messages(list, mail)
      if mail.header_fields.any?{|f| f.name =~ /^X-MS-Exchange-/i } &&
          !mail[:content_type].blank? &&
          mail[:content_type].content_type == 'multipart/mixed' && mail.parts.size > 2 &&
          mail.parts[0][:content_type].content_type == 'text/plain' &&
          mail.parts[0].body.to_s.blank? &&
          mail.parts[1][:content_type].content_type == 'application/pgp-encrypted' &&
          mail.parts[2][:content_type].content_type == 'application/octet-stream'
        mail.parts.delete_at(0)
        mail.content_type = [:multipart, :encrypted, {protocol: 'application/pgp-encrypted', boundary: mail.boundary}]
      end
    end
  end
end


