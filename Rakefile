project = 'schleuder'
require_relative "lib/#{project}.rb"

@version = Schleuder::VERSION
@tagname = "#{project}-#{@version}"
@gpguid = 'B3D190D5235C74E1907EACFE898F2C91E2E6E1F3'
@filename_gem = "#{@tagname}.gem"
@filename_tarball = "#{@tagname}.tar.gz"

load 'active_record/railties/databases.rake'

# Configure ActiveRecord
ActiveRecord::Tasks::DatabaseTasks.tap do |config|
  config.root = File.dirname(__FILE__)
  config.db_dir = 'db'
  config.migrations_paths = ['db/migrate']
  config.env = ENV['SCHLEUDER_ENV']
  config.database_configuration = Schleuder::Conf.databases
end

# ActiveRecord requires this task to be present
Rake::Task.define_task('db:environment')

namespace :db do
  # A shortcut.
  task init: ['db:create', 'db:schema:load']
end

def edit_and_add_file(filename)
  puts "Please edit #{filename} to refer to version #{@version}"
  if system("gvim -f #{filename}.md")
    `git add #{filename}.md`
  else
    exit 1
  end
end

task :console do
  exec "irb -r #{File.dirname(__FILE__)}/lib/schleuder.rb"
end

task :publish_gem => :website
task :git_tag => :check_version

desc 'Build new version: git-tag and gem-file'
task :new_version => [
    :check_version,
    :edit_readme, :edit_changelog,
    :git_add_version,
    :git_commit,
    :build_gem,
    :sign_gem,
    :build_tarball,
    :sign_tarball,
    :ensure_permissions,
    :git_tag
  ] do
end

desc 'Edit CHANGELOG.md'
task :edit_changelog do
  edit_and_add_file('CHANGELOG')
end

desc 'Edit README'
task :edit_readme do
  edit_and_add_file('README')
end

desc 'git-tag HEAD as new version'
task :git_tag do
  `git tag -u #{@gpguid} -s -m "Version #{@version}" #{@tagname}`
end

desc 'Add changed version to git-index'
task :git_add_version do
  `git add lib/#{project}/version.rb`
end

desc 'Commit changes as new version'
task :git_commit do
  `git commit -m "Version #{@version}"`
end

desc 'Build, sign and commit a gem-file.'
task :build_gem do
  `gem build #{project}.gemspec`
end

desc 'OpenPGP-sign gem and tarball'
task :sign_tarball do
  `gpg -u #{@gpguid} -b #{@filename_tarball}`
end

desc 'OpenPGP-sign gem'
task :sign_gem do
  `gpg -u #{@gpguid} -b #{@filename_gem}`
end

desc 'Ensure download-files have correct permissions'
task :ensure_permissions do
  File.chmod(0644, *Dir.glob("#{@tagname}*"))
end

desc 'Upload download-files (gem, tarball, signatures) to schleuder.org.'
task :upload_files do
  puts `echo "put -p #{@tagname}* www/download/" | sftp schleuder.org@ftp.schleuder.org 2>&1`
end

desc 'Publish gem-file to rubygems.org'
task :publish_gem do
  puts "Really push #{@filename_gem} to rubygems.org? [yN]"
  if $stdin.gets.match(/^y/i)
    puts 'Pushing...'
    `gem push #{@filename_gem}`
  else
    puts 'Not pushed.'
  end
end

desc 'Build and sign a tarball'
task :build_tarball do
  `git archive --format tar.gz --prefix "#{@tagname}/" -o #{@filename_tarball} master`
end

desc 'Describe manual release-tasks'
task :website do
  puts 'Please remember to publish the release-notes on the website and on schleuder-announce.'
end

desc 'Check if version-tag already exists'
task :check_version do
  # Check if Schleuder::VERSION has been updated since last release
  if `git tag`.match?(/^#{@tagname}$/)
    $stderr.puts "Warning: Tag '#{@tagname}' already exists. Did you forget to update lib/#{project}/version.rb?"
    $stderr.print 'Delete tag to continue? [yN] '
    if $stdin.gets.match(/^y/i)
      `git tag -d #{@tagname}`
    else
      exit 1
    end
  end
end

