class RenameDeliveryDisabledToDeliveryEnabledAndChangeDefault < ActiveRecord::Migration
  def up
    rename_column :subscriptions, :delivery_disabled, :delivery_enabled
    change_column_default :subscriptions, :delivery_enabled, true
  end

  def down
    rename_column :subscriptions, :delivery_enabled, :delivery_disabled
    change_column_default :subscriptions, :delivery_disabled, false
  end
end
