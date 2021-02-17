module Schleuder
  module Filters
    def self.forward_to_owner(list, mail)
      return if ! mail.to_owner?

      list.logger.debug 'Forwarding addressed to -owner'
      mail.add_pseudoheader(:note, I18n.t(:owner_forward_prefix))
      cleanmail = mail.clean_copy(true)
      list.admins.each do |admin|
        list.logger.debug "Forwarding message to #{admin}"
        admin.send_mail(cleanmail)
      end
      exit
    end
  end
end

