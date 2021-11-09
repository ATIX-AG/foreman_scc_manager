require File.expand_path('lib/foreman_scc_manager/version', __dir__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'foreman_scc_manager'
  s.version     = ForemanSccManager::VERSION
  s.date        = Date.today.to_s
  s.license     = 'GPL-3.0'
  s.authors     = ['ATIX AG']
  s.email       = ['info@atix.de']
  s.homepage    = 'https://www.orcharhino.com/'
  s.summary     = 'Suse Customer Center plugin for Foreman'
  # also update locale/gemspec.rb
  s.description = 'Foreman plugin to sync SUSE Customer Center products and repositories into Katello.'

  s.files = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_development_dependency 'rdoc', '~> 6', '>= 6.3.1'
  s.add_development_dependency 'rubocop', '~> 0.89.0'
  s.add_development_dependency 'rubocop-rails', '~> 2.8.1'

  # Testing
  s.add_development_dependency 'webmock'

  s.add_dependency 'foreman-tasks', '>= 0.10'
  s.add_dependency 'rails', '>= 5.1'
end
