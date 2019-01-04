class AddInternalFooterToList < ActiveRecord::Migration[5.2]
  def up
    if ! column_exists?(:lists, :internal_footer)
      add_column :lists, :internal_footer, :text, default: ''
    end
  end

  def down
    remove_column(:lists, :internal_footer)
  end
end
