class CreateLists < ActiveRecord::Migration[5.2]
  def up
    if ! table_exists?(:lists)
      create_table :lists do |t|
        t.timestamps
        t.string  :email
        t.string  :fingerprint
        t.string  :gpg_passphrase
        t.string  :log_level, default: 'warn'
        t.string  :default_mime, default: 'mime'
        t.string  :subject_prefix, default: ''
        t.string  :subject_prefix_in, default: ''
        t.string  :subject_prefix_out, default: ''
        t.string  :openpgp_header_preference, default: 'signencrypt'
        t.text    :public_footer, default: ''
        t.text    :headers_to_meta, default: '["from","to","date",":cc"]'
        t.text    :bounces_drop_on_headers, default: '{"x-spam-flag":"yes"}'
        t.text    :keywords_admin_only, default: '["unsubscribe", "unsubscribe", "delete-key"]'
        t.text    :keywords_admin_notify, default: '["add-key"]'
        t.boolean :send_encrypted_only, default: false
        t.boolean :receive_encrypted_only, default: false
        t.boolean :receive_signed_only, default: false
        t.boolean :receive_authenticated_only, default: false
        t.boolean :receive_from_subscribed_emailaddresses_only, default: false
        t.boolean :receive_admin_only, default: false
        t.boolean :keep_msgid, default: true
        t.boolean :bounces_drop_all, default: false
        t.boolean :bounces_notify_admins, default: true
        t.boolean :include_list_headers, default: true
        t.boolean :include_openpgp_header, default: true
        t.integer :max_message_size_kb, default: 10240
      end
    end

    def down
      drop_table(:lists)
    end
  end
end
