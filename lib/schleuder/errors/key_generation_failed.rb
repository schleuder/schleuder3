module Schleuder
  module Errors
    class KeyGenerationFailed < Base
      def initialize(listdir, listname)
        super t('errors.key_generation_failed', listdir: listdir, listname: listname)
      end
    end
  end
end
