module Schleuder
  module PluginRunners
    module Base
      def run(list, mail)
        list.logger.debug "Starting #{self}"
        @list = list
        @mail = mail
        setup

        output = mail.keywords.map do |keyword, arguments|
          run_plugin(keyword, arguments)
        end

        output.flatten.compact
      end


      private


      def run_plugin(keyword, arguments)
        @list.logger.debug "Running keyword '#{keyword}'"

        error = check_admin_only(keyword)
        return error if error

        command = keyword.gsub('-', '_')
        if ['list_name', 'listname', 'stop'].include? (command)
          return nil
        elsif ! @plugin_module.respond_to?(command)
          return I18n.t('plugins.unknown_keyword', keyword: keyword)
        else
          response = run_command(command, arguments)
          if @list.keywords_admin_notify.include?(keyword)
            notify_admins(keyword, arguments, response)
          end
          return response
        end
      rescue => exc
        # Log to system, this information is probably more useful for
        # system-admins than for list-admins.
        Schleuder.logger.error(exc.message_with_backtrace)
        I18n.t("plugins.plugin_failed", keyword: keyword)
      end

      def run_command(command, arguments)
        out = @plugin_module.send(command, arguments, @list, @mail)
        Array(out).flatten
      end

      def check_admin_only(keyword)
        if @list.admin_only?(keyword) && ! @list.from_admin?(@mail)
          @list.logger.debug "Error: Keyword is admin-only, sent by non-admin"
          Schleuder::Errors::KeywordAdminOnly.new(keyword).to_s
        else
          false
        end
      end

      def setup
        check_listname_keyword
        load_plugin_files
        @plugin_module = self.name.demodulize.gsub("Runner", "").constantize
      end

      def check_listname_keyword
        return nil if @mail.keywords.blank?

        listname_kw = @mail.keywords.assoc('list-name') || @mail.keywords.assoc('listname')
        if listname_kw.blank?
          @mail.reply_to_signer I18n.t(:missing_listname_keyword_error)
          exit
        else
          listname_args = listname_kw.last
          if ! [@list.email, @list.request_address].include?(listname_args.first)
            @mail.reply_to_signer I18n.t(:wrong_listname_keyword_error)
            exit
          end
        end

        if @mail.keywords.assoc('stop').blank?
          @mail.reply_to_signer I18n.t('errors.keyword_x_stop_missing')
          exit
        end
      end

      def load_plugin_files
        @list.logger.debug "Loading plugins"
        Dir["#{Schleuder::Conf.plugins_dir}/*.rb"].each do |file|
          require file
        end
      end

    end
  end
end
