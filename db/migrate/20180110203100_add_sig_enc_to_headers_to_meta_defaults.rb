class AddSigEncToHeadersToMetaDefaults < ActiveRecord::Migration[4.2]
  def up
    change_column_default :lists, :headers_to_meta, '["from", "to", "cc", "date", "sig", "enc"]'
    list_klass = create_list_klass
    list_klass.reset_column_information
    list_klass.find_each do |list|
      if (list.headers_to_meta & ['sig', 'enc']).empty?
        list.update(headers_to_meta: list.headers_to_meta + ['sig', 'enc'])
      end
    end
  end

  def down
    change_column_default :lists, :headers_to_meta, '["from", "to", "cc", "date"]'
    list_klass = create_list_klass
    list_klass.reset_column_information
    list_klass.find_each do |list|
      list.update(headers_to_meta: list.headers_to_meta - ['enc','sig'])
    end
  end

  def create_list_klass
    # Use a temporary class-definition to be independent of the
    # complexities of the actual class.
    Class.new(ActiveRecord::Base) do
      self.table_name = 'lists'
      self.serialize :headers_to_meta, JSON
    end
  end
end
