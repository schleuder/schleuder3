class AddSetReplyToToSenderAndMungeFrom < ActiveRecord::Migration[4.2]
  def up
    if ! column_exists?(:lists, :set_reply_to_to_sender)
      add_column :lists, :set_reply_to_to_sender, :boolean, default: false
    end
    if ! column_exists?(:lists, :munge_from)
      add_column :lists, :munge_from, :boolean, default: false
    end
  end

  def down
    remove_column(:lists, :set_reply_to_to_sender)
    remove_column(:lists, :munge_from)
  end
end
