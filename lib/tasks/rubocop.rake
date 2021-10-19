# frozen_string_literal: true

begin
  require 'rubocop/rake_task'

  test_patterns = [
    "#{ForemanSccManager::Engine.root}/*.gemspec",
    "#{ForemanSccManager::Engine.root}/*.rb",
    "#{ForemanSccManager::Engine.root}/app/**/*.rb",
    "#{ForemanSccManager::Engine.root}/config/**/*.rb",
    "#{ForemanSccManager::Engine.root}/db/**/*.rb",
    "#{ForemanSccManager::Engine.root}/lib/**/*.rake",
    "#{ForemanSccManager::Engine.root}/lib/**/*.rb",
    "#{ForemanSccManager::Engine.root}/test/**/*.rb",
  ]

  namespace :foreman_scc_manager do
    desc 'Runs Rubocop style checker'
    RuboCop::RakeTask.new(:rubocop) do |task|
      task.patterns = test_patterns
    end

    desc 'Runs Rubocop style checker with xml output for Jenkins'
    RuboCop::RakeTask.new('rubocop:jenkins') do |task|
      task.patterns = test_patterns
      task.requires = ['rubocop/formatter/checkstyle_formatter']
      task.formatters = ['RuboCop::Formatter::CheckstyleFormatter']
      task.options = ['--no-color', '--out', 'rubocop.xml']
    end
  end
rescue LoadError
  puts 'Rubocop not loaded.'
end
