module Schleuder
  module Errors
    class MessageTooBig < Base
      def initialize(list)
        set_default_locale
        allowed_size = list.max_message_size_kb
        super t('errors.message_too_big', allowed_size: allowed_size)
      end
    end
  end
end
