#!/usr/bin/env rake

require 'pg_global_search'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new :spec
rescue LoadError
  puts "Couldn't find rspec"
  exit
end

desc 'Copies the test db config'
task :setup_test_database_yml do
  FileUtils.cp File.expand_path("spec/dummy/config/default.database.yml"), File.expand_path("spec/dummy/config/database.yml")
end

Rake::Task[:spec].prerequisites << :setup_test_database_yml

task :default => :spec