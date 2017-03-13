require File.expand_path('../lib/foreman_scc_manager/version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'foreman_scc_manager'
  s.version     = ForemanSccManager::VERSION
  s.date        = Date.today.to_s
  s.license     = 'GPL-3.0'
  s.authors     = ['Matthias Dellweg']
  s.email       = ['dellweg@atix.de']
  s.homepage    = ''
  s.summary     = 'ForemanSccManager.'
  # also update locale/gemspec.rb
  s.description = 'Description of ForemanSccManager.'

  s.files = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_development_dependency 'rails'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rdoc'
end
