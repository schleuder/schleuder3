module Schleuder
  module Filters
    def self.receive_signed_only(list, mail)
      if list.receive_signed_only? && ! mail.was_validly_signed?
        list.logger.info 'Rejecting mail as unsigned'
        return Errors::MessageUnsigned.new
      end
    end
  end
end
