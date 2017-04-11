require File.expand_path('../lib/foreman_scc_manager/version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'foreman_scc_manager'
  s.version     = ForemanSccManager::VERSION
  s.date        = Date.today.to_s
  s.license     = 'GPL-3.0'
  s.authors     = ['ATIX AG']
  s.email       = ['info@atix.de']
  s.homepage    = 'https://www.orcharhino.com/'
  s.summary     = 'ForemanSccManager.'
  # also update locale/gemspec.rb
  s.description = 'Foreman plugin to sync SUSE Customer Center products and repositories into Katello.'

  s.files = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_development_dependency 'rails', '~> 4'
  s.add_development_dependency 'rubocop', '~> 0'
  s.add_development_dependency 'rdoc', '~> 4'
end
