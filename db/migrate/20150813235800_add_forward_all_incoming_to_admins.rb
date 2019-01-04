class AddForwardAllIncomingToAdmins < ActiveRecord::Migration[5.2]
  def up
    if ! column_exists?(:lists, :forward_all_incoming_to_admins)
      add_column :lists, :forward_all_incoming_to_admins, :boolean, default: false
    end
  end

  def down
    remove_column(:lists, :forward_all_incoming_to_admins)
  end
end
