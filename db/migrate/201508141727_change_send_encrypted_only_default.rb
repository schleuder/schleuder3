class ChangeSendEncryptedOnlyDefault < ActiveRecord::Migration[5.2]
  def up
    change_column_default :lists, :send_encrypted_only, true
  end
  def down
    change_column_default :lists, :send_encrypted_only, false
  end
end
