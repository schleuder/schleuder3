class AddLanguageToLists < ActiveRecord::Migration[4.2]
  def up
    if ! column_exists?(:lists, :language)
      add_column :lists, :language, :string, default: 'en'
    end
  end

  def down
    remove_column(:lists, :language)
  end
end
