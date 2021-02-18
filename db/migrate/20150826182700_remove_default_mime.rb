class RemoveDefaultMime < ActiveRecord::Migration[4.2]
  def up
    remove_column :lists, :default_mime
  end

  def down
    add_column :lists, :default_mime, :string, default: 'mime'
  end
end
