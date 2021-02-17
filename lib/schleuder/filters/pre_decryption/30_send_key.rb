module Schleuder
  module Filters
    def self.send_key(list, mail)
      return if ! mail.sendkey_request?

      list.logger.debug 'Sending public key as reply.'

      out = mail.reply
      out.from = list.email
      # We're not sending to a subscribed address, so we need to specify a envelope-sender manually.
      out.sender = list.bounce_address
      out.body = I18n.t(:list_public_key_attached)
      out.attach_list_key!(list)
      # TODO: find out why the gpg-module puts all the headers into the first mime-part, too
      out.gpg list.gpg_sign_options
      out.deliver
      exit
    end
  end
end
