module Schleuder
  module Filters
    def self.receive_admin_only(list, mail)
      if list.receive_admin_only? && ( ! mail.was_validly_signed? || ! mail.signer.admin? )
        list.logger.info 'Rejecting mail as not from admin.'
        return Errors::MessageNotFromAdmin.new
      end
    end
  end
end
