class CreateSubscriptions < ActiveRecord::Migration[5.2]
  def up
    if ! table_exists?(:subscriptions)
      create_table :subscriptions do |t|
        t.integer :list_id
        t.string  :email
        t.string  :fingerprint
        t.boolean :admin, default: false
        t.boolean :delivery_disabled, default: false
        t.timestamps
      end

      add_index :subscriptions, :list_id
      add_index :subscriptions, [:email, :list_id], unique: true
    end
  end

  def down
    drop_table(:subscriptions)
  end
end
