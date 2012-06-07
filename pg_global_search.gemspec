$:.unshift 'lib'

Gem::Specification.new do |s|
  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.name                  = 'pg_global_search'
  s.version               = "0.0.2"
  s.date                  = Time.now.strftime('%Y-%m-%d')
  s.homepage              = 'https://github.com/site5/pg_global_search'
  s.authors               = ['Fabio Kreusch']
  s.email                 = 'fabiokr@gmail.com'
  s.files                 = %w[ Rakefile README.markdown Gemfile pg_global_search.gemspec ]
  s.files                += Dir['lib/**/*', 'spec/**/*']

  s.add_dependency 'pg_search',         '~> 0.5'

  s.add_development_dependency 'rspec', '~> 2.10.0'
  s.add_development_dependency 'rake', '~> 0.9.2.2'
  s.add_development_dependency 'pg'

  s.extra_rdoc_files = ['README.markdown']
  s.rdoc_options     = ['--charset=UTF-8']

  s.summary = s.description = <<-DESC
    An ActiveRecord pg_search extension that allows you to search across all of your models
  DESC
end
