module Schleuder
  module Errors
    class TooManyKeys < Base
      def initialize(listdir, listname)
        super t('errors.too_many_keys', listdir: listdir, listname: listname)
      end
    end
  end
end

