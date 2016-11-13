module Schleuder
  class Subscription < ActiveRecord::Base
    belongs_to :list

    validates :list_id, inclusion: {
                          in: -> (id) { List.pluck(:id) },
                          message: "must refer to an existing list"
                        }
    validates :email, presence: true, email: true
    validates :fingerprint,
                format: { with: /\A[a-f0-9]+\z/i, allow_blank: true }
    validates :delivery_enabled, :admin, boolean: true

    default_scope { order(:email) }

    def to_s
      email
    end

    def self.configurable_attributes
      [:fingerprint, :admin, :delivery_enabled]
    end

    def fingerprint=(arg)
      # Strip whitespace from incoming arg.
      write_attribute(:fingerprint, arg.to_s.gsub(/\s*/, '').chomp)
    end

    def key
      # TODO: make key-related methods a concern, so we don't have to go
      # through the list and neither re-implement the methods here.
      # Prefix '0x' to force GnuPG to match only hex-values, not UIDs.
      list.keys("0x#{self.fingerprint}").first
    end

    def send_mail(mail)
      list.logger.debug "Preparing sending to #{self.inspect}"

      if ! self.delivery_enabled
        list.logger.info "Not sending to #{self.email}: delivery is disabled."
        return false
      end

      mail = ensure_headers(mail)
      gpg_opts = {encrypt: true, sign: true, keys: {self.email => "0x#{self.fingerprint}"}}
      if self.key.blank?
        if self.list.send_encrypted_only?
          self.list.logger.warn "Not sending to #{self.email}: no key present and sending plain text not allowed"
          notify_of_missed_message
          return false
        else
          gpg_opts.merge!(encrypt: false)
        end
      end
      list.logger.info "Sending message to #{self.email}"
      mail.gpg gpg_opts
      mail.deliver
    end

    def ensure_headers(mail)
      mail.to = self.email
      mail.from = self.list.email
      mail.return_path = self.list.bounce_address
      mail
    end

    def notify_of_missed_message
      mail = ensure_headers(Mail.new)
      mail.subject = I18n.t('notice')
      mail.body = I18n.t("missed_message_due_to_absent_key", list_email: self.list.email) + I18n.t('errors.signoff')
      mail.gpg({encrypt: false, sign: true})
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
