require 'spec_helper'

describe 'AddSigEncToHeadersToMetaDefaults' do
  let(:migrations) { ActiveRecord::Migration[5.2].new.migration_context.migrations }
  let(:migration_under_test) { 20180110203100 }
  let(:previous_migration) { 20170713215059 }

  after(:each) do
    ActiveRecord::Migrator.new(:up, migrations).migrate
    List.reset_column_information
  end

  describe 'up' do
    it 'sets the column defaults' do
      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass = create_list_klass
      list_klass.reset_column_information

      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      list_klass.reset_column_information

      expect(list_klass.column_defaults['headers_to_meta']).to eql(["from", "to", "cc", "date", "sig", "enc"])
    end

    it 'adds sig and enc to headers_to_meta for lists without the attributes' do
      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass = create_list_klass
      list = list_klass.create!(headers_to_meta: list_klass.column_defaults['headers_to_meta'])

      expect(list.headers_to_meta).not_to include('enc', 'sig')

      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      list_klass.reset_column_information
      list.reload

      expect(list.headers_to_meta).to include('enc', 'sig')
    end

    it 'does not add sig and enc to headers to meta if the attributes already exist' do
      headers_to_meta_including_sig_and_enc = ['from', 'to', 'cc', 'date', 'sig', 'enc']
      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass = create_list_klass
      list = list_klass.create!(headers_to_meta: headers_to_meta_including_sig_and_enc)

      expect(list.headers_to_meta).to eql headers_to_meta_including_sig_and_enc

      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      list_klass.reset_column_information
      list.reload

      expect(list.headers_to_meta).to eql headers_to_meta_including_sig_and_enc
    end
  end

  describe 'down' do
    it 'sets the column defaults' do
      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      list_klass = create_list_klass
      list_klass.reset_column_information

      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass.reset_column_information

      expect(list_klass.column_defaults['headers_to_meta']).to eql(["from", "to", "cc", "date"])
    end

    it 'removes sig and enc from headers_to_meta from existing lists' do
      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      list_klass = create_list_klass
      list_klass.reset_column_information
      list = list_klass.create!(headers_to_meta: list_klass.column_defaults['headers_to_meta'])

      expect(list.headers_to_meta).to include('enc', 'sig')

      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass.reset_column_information
      list.reload

      expect(list.headers_to_meta).not_to include('enc', 'sig')
    end
  end

  def create_list_klass
    Class.new(ActiveRecord::Base) do
      self.table_name = 'lists'
      self.serialize :headers_to_meta, JSON
    end
  end
end
