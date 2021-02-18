class FixHeadersToMetaDefaults < ActiveRecord::Migration[4.2]
  def up
    change_column_default :lists, :headers_to_meta, '["from", "to", "date", "cc"]'
  end

  def down
  end
end
