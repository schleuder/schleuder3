module Schleuder
  module Filters
    def self.receive_encrypted_only(list, mail)
      if list.receive_encrypted_only? && ! mail.was_encrypted?
        list.logger.info 'Rejecting mail as unencrypted'
        return Errors::MessageUnencrypted.new
      end
    end
  end
end
