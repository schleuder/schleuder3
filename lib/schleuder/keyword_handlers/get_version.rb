module Schleuder
  module KeywordHandlers
    class GetVersion < Base
      handles_request_keyword 'get-version', with_method: :get_version

      def get_version
        Schleuder::VERSION
      end
    end
  end
end
