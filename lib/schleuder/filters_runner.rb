module Schleuder
  module Filters
    class Runner
      attr_reader :list, :filter_type

      def initialize(list, filter_type)
        @list = list
        @filter_type = filter_type
      end

      def run(mail)
        filters.map do |cmd|
          list.logger.debug "Calling filter #{cmd}"
          response = Filters.send(cmd, list, mail)
          if stop?(response)
            if bounce?(response, mail)
              return response
            else
              return nil
            end
          end
        end
        nil
      end

      def filters
        @filters ||= load_filters
      end

      private
      def stop?(response)
        response.kind_of?(StandardError)
      end

      def bounce?(response, mail)
        if list.bounces_drop_all
          list.logger.debug 'Dropping bounce as configurated'
          notify_admins(I18n.t('.bounces_drop_all'), mail.original_message)
          return false
        end

        list.bounces_drop_on_headers.each do |key, value|
          if mail[key].to_s.match(/#{value}/i)
            list.logger.debug "Incoming message header key '#{key}' matches value '#{value}': dropping the bounce."
            notify_admins(I18n.t('.bounces_drop_on_headers', key: key, value: value), mail.original_message)
            return false
          end
        end

        list.logger.debug 'Bouncing message'
        true
      end

      def notify_admins(reason, original_message)
        if list.bounces_notify_admins?
          list.logger.notify_admin reason, original_message, I18n.t('notice')
        end
      end

      def load_filters
        list.logger.debug "Loading #{filter_type}_decryption filters"
        sorted_filters.map do |filter_name|
          require all_filter_files[filter_name]
          filter_name.split('_',2).last
        end
      end

      def sorted_filters
        @sorted_filters ||= all_filter_files.keys.sort do |a,b|
          a.split('_',2).first.to_i <=> b.split('_',2).first.to_i
        end
      end

      def all_filter_files
        @all_filter_files ||= begin
          files_in_filter_dirs = Dir[*filter_dirs]
          files_in_filter_dirs.inject({}) do |res,file|
            filter_name = File.basename(file,'.rb')
            res[filter_name] = file
            res
          end
        end
      end

      def filter_dirs
        @filter_dirs ||= [File.join(File.dirname(__FILE__),'filters'),
                          Schleuder::Conf.filters_dir].map do |d|
                            File.join(d,"#{filter_type}_decryption/[0-9]*_*.rb")
                          end
      end
    end
  end
end
