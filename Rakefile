#!/usr/bin/env rake

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new :spec
rescue LoadError
  puts "Couldn't find rspec"
  exit
end

task :default => :spec

namespace :pg_global_search do
end
