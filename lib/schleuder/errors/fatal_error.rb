module Schleuder
  module Errors
    class FatalError < Base
      def initialize
      end

      def to_s
        t('errors.fatalerror')
      end
    end
  end
end

