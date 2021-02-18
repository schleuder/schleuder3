class ChangeKeywordsAdminOnlyDefaults < ActiveRecord::Migration[4.2]
  def up
    change_column_default :lists, :keywords_admin_only, "[\"subscribe\", \"unsubscribe\", \"delete-key\"]"
  end
  def down
    change_column_default :lists, :keywords_admin_only, "[\"unsubscribe\", \"unsubscribe\", \"delete-key\"]"
  end
end
