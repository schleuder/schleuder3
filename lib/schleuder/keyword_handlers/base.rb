module Schleuder
  module KeywordHandlers
    class Base
      class << self
        def handles_request_keyword(keyword, with_method:, has_aliases: [])
          KeywordHandlersRunner.register_keyword(
            type: :request,
            keyword: keyword,
            handler_class: self,
            handler_method: with_method,
            aliases: has_aliases
          )
        end

        def handles_list_keyword(keyword, with_method:, has_aliases: [])
          KeywordHandlersRunner.register_keyword(
            type: :list,
            keyword: keyword,
            handler_class: self,
            handler_method: with_method,
            aliases: has_aliases
          )
        end
      end

      attr_reader :arguments
      attr_reader :mail

      def initialize(mail:, arguments:)
        @arguments = arguments
        @mail = mail
        @list = mail.list
      end
    end
  end
end
