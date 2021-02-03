module Schleuder
  module Errors
    class Base < StandardError
      def t(key, **kwargs)
        I18n.t(key, **kwargs)
      end

      def to_s
        super + t('errors.signoff')
      end

      def set_default_locale
        I18n.locale = I18n.default_locale
      end
    end
  end
end
