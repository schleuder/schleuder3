module Schleuder
  module Filters
    def self.receive_authenticated_only(list, mail)
      if list.receive_authenticated_only? && ( ! mail.was_encrypted? || ! mail.was_validly_signed? )
        list.logger.info 'Rejecting mail as unauthenticated'
        return Errors::MessageUnauthenticated.new
      end
    end
  end
end
