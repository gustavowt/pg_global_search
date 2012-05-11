$:.unshift 'lib'

require 'pg_global_search/version'

Gem::Specification.new do |s|
  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.name                  = 'pg_global_search'
  s.version               = PgGlobalSearch::Version
  s.date                  = Time.now.strftime('%Y-%m-%d')
  s.homepage              = 'https://github.com/site5/pg_global_search'
  s.authors               = ['Fabio Kreusch']
  s.email                 = 'fabiokr@gmail.com'
  s.files                 = %w[ Rakefile README.markdown Gemfile pg_global_search.gemspec ]
  s.files                += Dir['lib/**/*', 'spec/**/*', 'app/**/*']

  s.add_dependency 'pg_search',         '~> 0.4.1'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake', '~> 0.9.2.2'

  s.extra_rdoc_files = ['README.markdown']
  s.rdoc_options     = ['--charset=UTF-8']

  s.summary = s.description = <<-DESC
    An ActiveRecord pg_search extension that allows you to search across all of your models
  DESC
end
