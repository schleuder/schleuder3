module Schleuder
  module Filters

    def self.max_message_size(list, mail)
      if (mail.raw_source.size / 1024) > list.max_message_size_kb
        list.logger.info 'Rejecting mail as too big'
        return Errors::MessageTooBig.new(list)
      end
    end

  end
end


