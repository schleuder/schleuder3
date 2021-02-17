module Schleuder
  module Filters
    def self.receive_from_subscribed_emailaddresses_only(list, mail)
      if list.receive_from_subscribed_emailaddresses_only? && list.subscriptions.where(email: mail.from.first).blank?
        list.logger.info 'Rejecting mail as not from subscribed address.'
        return Errors::MessageSenderNotSubscribed.new
      end
    end
  end
end
