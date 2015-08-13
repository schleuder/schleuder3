module Schleuder
  module Errors
    class MessageUnsigned < Base
      def initialize(list)
        @list = list
      end

      def message
        t('errors.message_unsigned')
      end
    end
  end
end
