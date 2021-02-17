module Schleuder
  module Filters
    def self.forward_bounce_to_admins(list, mail)
      if mail.automated_message?
        list.logger.info 'Forwarding automated message to admins'
        list.logger.notify_admin I18n.t(:forward_automated_message_to_admins), mail.original_message, I18n.t('automated_message_subject')
        exit
      end
    end
  end
end

