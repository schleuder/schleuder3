class AddAutocryptHeaderToList < ActiveRecord::Migration[4.2]
  def up
    if ! column_exists?(:lists, :include_autocrypt_header)
      add_column :lists, :include_autocrypt_header, :boolean, default: true
    end
  end

  def down
    remove_column(:lists, :include_autocrypt_header)
  end
end
