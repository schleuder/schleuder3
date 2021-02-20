#!/usr/bin/ruby
# Inspired from
# https://github.com/sds/overcommit/blob/f8a27d6c973a12df6f0281848b10a6f6cdaa982f/lib/overcommit/hook/pre_commit/rails_schema_up_to_date.rb
db_path = File.expand_path(File.join(File.dirname(__FILE__), '../../db'))
migration_files = Dir.glob("#{db_path}/migrate/*.rb")
latest_version = migration_files.map do |file|
  File.basename(file)[/\d+/]
end.max
schema_file = "#{db_path}/schema.rb"
schema = File.read(schema_file).tr('_', '')
schema_up_to_date = schema.include?(latest_version)
unless schema_up_to_date
  puts "The latest migration version you're committing is " \
    "#{latest_version}, but your schema file " \
    "#{schema_file} is on a different version."
  exit 1
end
