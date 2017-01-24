module Schleuder
  module Plugins
    class Runner
      def self.run(list, mail)
        list.logger.debug "Starting plugins runner"
        @list = list
        @mail = mail
        setup
        output = []
        if @mail.request?
          @plugin_module = RequestPlugins
        else
          @plugin_module = ListPlugins
        end
        mail.keywords.each do |keyword, arguments|
          @list.logger.debug "Running keyword '#{keyword}'"
          if @list.admin_only?(keyword) && ! @list.from_admin?(@mail)
            @list.logger.debug "Error: Keyword is admin-only, sent by non-admin"
            output << Schleuder::Errors::KeywordAdminOnly.new(keyword).to_s
            next
          end
          output << run_plugin(keyword, arguments)
        end
        output
      end

      def self.run_plugin(keyword, arguments)
        command = keyword.gsub('-', '_')
        if @plugin_module.respond_to?(command)
          out = @plugin_module.send(command, arguments, @list, @mail)
          response = Array(out).flatten.join("\n\n")
          if @list.keywords_admin_notify.include?(keyword)
            explanation = I18n.t('plugins.keyword_admin_notify', 
                                    signer: @mail.signer,
                                    keyword: keyword,
                                    response: response
                                )
            @list.logger.notify_admin("#{explanation}\n\n#{response}\n", nil, 'Notice')
          end
          response
        else
          I18n.t('plugins.unknown_keyword', keyword: keyword)
        end
      rescue => exc
        # Log to system, this information is probably more useful for
        # system-admins than for list-admins.
        Schleuder.logger.error(exc.message_with_backtrace)
        I18n.t("plugins.plugin_failed", keyword: keyword)
      end

      def self.setup
        @list.logger.debug "Loading plugins"
        Dir["#{Schleuder::Conf.plugins_dir}/*.rb"].each do |file|
          require file
        end
      end
    end

  end
end
