class AddLogfilesToKeepToLists < ActiveRecord::Migration[5.2]
  def up
    if ! column_exists?(:lists, :logfiles_to_keep)
      add_column :lists, :logfiles_to_keep, :integer, default: 2
    end
  end

  def down
    remove_column(:lists, :logfiles_to_keep)
  end
end
