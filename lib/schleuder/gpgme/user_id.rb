module GPGME
  class UserID
    def name
      sanitize_encoding(@name)
    end

    def comment
      sanitize_encoding(@comment)
    end

    def uid
      sanitize_encoding(@uid)
    end

    private
    def sanitize_encoding(str)
      if str.is_a?(String) && str.encoding != 'UTF-8'
        str.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '')
      else
        str
      end
    end
  end
end
