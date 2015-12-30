module Schleuder
  module RequestPlugins
    def self.add_key(arguments, list, mail)
      key_material = if mail.parts.first.present?
                       mail.parts.first.body
                     else
                       mail.body
                     end.to_s
      result = list.import_key(key_material)

      out = [I18n.t('plugins.key_management.import_result')]
      out << result.map do |fpr, action|
        str = I18n.t("plugins.key_management.key_import_status.#{action}")
        "#{fpr}: #{str}"
      end
    end

    def self.delete_key(arguments, list, mail)
      arguments.map do |argument|
        "Deleting #{argument}: #{list.gpg.delete(argument)}"
      end
    end

    def self.list_keys(arguments, list, mail)
      arguments.map do |argument|
        list.keys(argument).map do |key|
          key.to_s
        end
      end
    end

    def self.get_key(arguments, list, mail)
      arguments.map do |argument|
        GPGME::Key.export(argument)
      end
    end

    def self.fetch_key(arguments, list, mail)
      hkp = Hkp.new
      arguments.map do |argument|
        hkp.fetch_and_import(argument)
      end
    end
  end
end
