class RenameDeliveryDisabledToDeliveryEnabledAndChangeDefault < ActiveRecord::Migration[4.2]
  def up
    if column_exists?(:subscriptions, :delivery_disabled)
      rename_column :subscriptions, :delivery_disabled, :delivery_enabled
      change_column_default :subscriptions, :delivery_enabled, true
    end
  end

  def down
    rename_column :subscriptions, :delivery_enabled, :delivery_disabled
    change_column_default :subscriptions, :delivery_disabled, false
  end
end

