module Schleuder
  class Subscription < ActiveRecord::Base
    belongs_to :list

    validates :list_id, inclusion: {
                          in: -> (id) { List.pluck(:id) },
                          message: "must refer to an existing list"
                        }
    validates :email, presence: true, email: true, uniqueness: {scope: :list_id}
    validates :fingerprint, allow_blank: true, fingerprint: true
    validates :delivery_enabled, :admin, boolean: true

    before_validation {
      self.email = Mail::Address.new(self.email).address
    }

    default_scope { order(:email) }

    scope :without_fingerprint, -> { where(fingerprint: [nil,'']) }

    def to_s
      email
    end

    def self.configurable_attributes
      ['fingerprint', 'admin', 'delivery_enabled']
    end

    def fingerprint=(arg)
      # Always assign the given value, because it must be possible to overwrite
      # the previous fingerprint with an empty value. That value should better
      # be nil instead of a blank string, but currently schleuder-cli (v0.1.0) expects
      # only strings.
      write_attribute(:fingerprint, arg.to_s.gsub(/\s*/, '').gsub(/^0x/, '').chomp.upcase)
    end

    def key
      # TODO: make key-related methods a concern, so we don't have to go
      # through the list and neither re-implement the methods here.
      # Prefix '0x' to force GnuPG to match only hex-values, not UIDs.
      @key ||= list.keys("0x#{self.fingerprint}").first
    end

    def send_mail(mail, incoming_mail=nil)
      list.logger.debug "Preparing sending to #{self.inspect}"

      mail = ensure_headers(mail, incoming_mail)
      gpg_opts = self.list.gpg_sign_options

      if self.key.blank?
        if self.list.send_encrypted_only?
          notify_of_missed_message(:absent)
          return false
        else
          list.logger.warn "Sending plaintext because no key is present!"
        end
      elsif ! self.key.usable?
        if self.list.send_encrypted_only?
          notify_of_missed_message(key.usability_issue)
          return false
        else
          list.logger.warn "Sending plaintext because assigned key is #{key.usability_issue}!"
        end
      else
        gpg_opts.merge!(encrypt: true, keys: {self.email => "0x#{self.fingerprint}"})
      end

      list.logger.info "Sending message to #{self.email}"
      mail.gpg gpg_opts
      mail.deliver
    end

    def ensure_headers(mail, incoming_mail=nil)
      mail.to = self.email
      
      if self.list.set_reply_to_to_sender? && ! incoming_mail.nil?
        # If the option "set_reply_to_to_sender" is set to true, we will set the reply-to header 
        # to the reply-to header given by the original email. If no reply-to header exists in the original email,
        # the original senders email will be used as reply-to.
        if ! incoming_mail.reply_to.nil?
          mail.reply_to = incoming_mail.reply_to
        else
          mail.reply_to = incoming_mail.from
        end
      end

      if self.list.munge_from? && ! incoming_mail.nil? 
        # If the option "munge_from" is set to true, we will add the original senders' from-header to ours.
        # We munge the from-header to avoid issues with DMARC.
        mail.from = I18n.t("header_munging", from: incoming_mail.from.first, list: self.list.email, list_address: self.list.email)
      else
        mail.from = self.list.email
      end

      mail.sender = self.list.bounce_address
      mail
    end

    def notify_of_missed_message(reason)
      self.list.logger.warn "Not sending to #{self.email}: key is unusable because it is #{reason} and sending plain text not allowed"
      mail = ensure_headers(Mail.new)
      mail.subject = I18n.t('notice')
      mail.body = I18n.t("missed_message_due_to_unusable_key", list_email: self.list.email) + I18n.t('errors.signoff')
      mail.gpg self.list.gpg_sign_options
      mail.deliver
    end

    def admin?
      self.admin == true
    end

    def delete_key
      list.delete_key(self.fingerprint)
    end

  end
end
