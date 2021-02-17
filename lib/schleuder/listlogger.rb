module Schleuder
  class Listlogger < ::Logger
    include LoggerNotifications
    def initialize(list)
      super(list.logfile, 'daily')
      @from = list.email
      @list = list
      @adminaddresses = list.admins.map { |sub| [sub.email, sub.key] }
      @level = ::Logger.const_get(list.log_level.upcase)
      remove_old_logfiles(list)
    end

    # Logger rotates but doesn't delete older files, so we're helping
    # ourselves.
    def remove_old_logfiles(list)
      logfiles_to_keep = list.logfiles_to_keep.to_i
      if logfiles_to_keep < 1
        logfiles_to_keep = list.class.column_defaults['logfiles_to_keep']
      end
      suffix_now = Time.now.strftime('%Y%m%d').to_i
      del_older_than = suffix_now - logfiles_to_keep
      Pathname.glob("#{list.logfile}.????????").each do |file|
        if file.basename.to_s.match(/\.([0-9]{8})$/)
          if del_older_than.to_i >= $1.to_i
            file.unlink
          end
        end
      end
    end
  end
end
