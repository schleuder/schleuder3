class AddDeliverSelfsentToList < ActiveRecord::Migration[4.2]
  def up
    if ! column_exists?(:lists, :deliver_selfsent)
      add_column :lists, :deliver_selfsent, :boolean, default: true
    end
  end

  def down
    remove_column(:lists, :deliver_selfsent)
  end
end
