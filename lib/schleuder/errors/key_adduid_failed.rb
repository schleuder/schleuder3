module Schleuder
  module Errors
    class KeyAdduidFailed < Base
      def initialize(errmsg)
        super t('errors.key_adduid_failed', errmsg: errmsg)
      end
    end
  end
end
