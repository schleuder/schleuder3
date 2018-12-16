module Schleuder
  class KeywordHandlersRunner
    REGISTERED_KEYWORDS = {list: {}, request: {}}
    RESERVED_KEYWORDS = %w[list-name listname stop]

    class << self
      attr_reader :keywords

      def register_keyword(type:, keyword:, handler_class:, handler_method:, aliases:)
        assert_valid_input!(type: type, keyword: keyword, handler_class: handler_class, handler_method: handler_method)

        identifiers = [keyword] + Array(aliases)
        identifiers.each do |identifier|
          REGISTERED_KEYWORDS[type.to_sym][identifier.to_s.dasherize] = {
              klass: handler_class,
              method: handler_method.to_sym
            }
        end
      end

      def run(type:, list:, mail:)
        list.logger.debug "Starting #{self}"
        assert_valid_type!(type)
        load_additional_keyword_handlers

        error = check_unknown_keywords(mail, type)
        return error if error.present?

        error = check_mandatory_keywords(mail, list)
        return [error] if error.present?

        output = mail.keywords.map do |keyword, arguments|
          if ! is_reserved_keyword?(keyword)
            run_handler(mail, list, type, keyword.to_s.dasherize, Array(arguments))
          end
        end

        output.flatten.compact
      end


      private


      def check_unknown_keywords(mail, type)
        known_keywords = REGISTERED_KEYWORDS[type.to_sym].keys + RESERVED_KEYWORDS
        given_keywords = mail.keywords.map(&:first)
        unknown_keywords = given_keywords - known_keywords
        if unknown_keywords.present?
          error_messages = unknown_keywords.map do |keyword|
            I18n.t('errors.unknown_keyword', keyword: keyword)
          end
          return error_messages
        end
      end

      def run_handler(mail, list, type, keyword, arguments)
        list.logger.debug "run_handler() with keyword '#{keyword}'"

        keyword_data = REGISTERED_KEYWORDS[type.to_sym][keyword]
        handler_class = keyword_data[:klass]
        handler_method = keyword_data[:method]
        output = handler_class.new(mail: mail, arguments: arguments).send(handler_method)

        if list.keywords_admin_notify.include?(keyword)
          notify_admins(type, mail, list, keyword, arguments, output)
        end
        return output
      rescue => exc
        # Log to system, this information is probably more useful for
        # system-admins than for list-admins.
        Schleuder.logger.error(exc.message_with_backtrace)
        I18n.t('keyword_handlers.handler_failed', keyword: keyword)
      end

      def notify_admins(type, mail, list, keyword, arguments, response)
        msg = I18n.t("keyword_handlers.keyword_admin_notify.#{type}",
                      sender: mail.signer,
                      keyword: keyword,
                      arguments: arguments.join(' '),
                      response: Array(response).join("\n\n")
                    )
        list.logger.notify_admin(msg, nil, 'Notice')
      end

      def load_additional_keyword_handlers
        Dir["#{Schleuder::Conf.keyword_handlers_dir}/*.rb"].each do |file|
          load file
        end
      end

      def check_mandatory_keywords(mail, list)
        return nil if mail.keywords.blank?

        listname_keyword = mail.keywords.assoc('list-name') || mail.keywords.assoc('listname')
        if listname_keyword.blank?
          return I18n.t(:missing_listname_keyword_error)
        else
          listname_args = listname_keyword.last
          if ! [list.email, list.request_address].include?(listname_args.first)
            return I18n.t(:wrong_listname_keyword_error)
          end
        end

        if mail.keywords.assoc('stop').blank?
          return I18n.t('errors.keyword_x_stop_missing')
        end
      end

      def is_reserved_keyword?(keyword)
        RESERVED_KEYWORDS.include?(keyword)
      end

      def assert_valid_input!(type:, keyword:, handler_class:, handler_method:)
        assert_valid_type!(type)
        assert_valid_keyword!(keyword)
        assert_valid_handler_class!(handler_class)
        assert_valid_handler_method!(handler_method)
      end

      def assert_valid_type!(type)
        if ! REGISTERED_KEYWORDS.keys.include?(type)
          raise ArgumentError.new("Argument must be one of #{REGISTERED_KEYWORDS.keys.inspect}, got: #{type.inspect}")
        end
      end

      def assert_valid_keyword!(keyword)
        if keyword.blank?
          raise ArgumentError.new("Invalid keyword: #{keyword.inspect}")
        end
      end

      def assert_valid_handler_class!(handler_class)
        if ! handler_class.is_a?(Class)
          raise ArgumentError.new("Invalid input for handler_class: #{handler_class.inspect} is not a class")
        end
      end

      def assert_valid_handler_method!(handler_method)
        if handler_method.blank?
          raise ArgumentError.new("Invalid input for handler_method: #{handler_method.inspect} is not a valid method name")
        end
      end
    end
  end
end
