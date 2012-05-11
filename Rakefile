#!/usr/bin/env rake

require 'pg_global_search'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new :spec
rescue LoadError
  puts "Couldn't find rspec"
  exit
end

desc 'Creates the test db'
task :create_test_db do
  %x( createdb -E UTF8 pg_global_search_test )
end

Rake::Task[:spec].prerequisites << :create_test_db

task :default => :spec