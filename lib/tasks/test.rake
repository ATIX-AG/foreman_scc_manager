require 'rake/testtask'

# Tests
namespace :test do
  desc 'Test ForemanSccManager'
  Rake::TestTask.new(:foreman_scc_manager) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end
end

namespace :jenkins do
  desc 'Test ForemanSccManager with XML output for jenkins'
  task 'foreman_scc_manager' => :environment do
    Rake::Task['jenkins:setup:minitest'].invoke
    Rake::Task['rake:test:foreman_scc_manager'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_scc_manager']

load 'tasks/jenkins.rake'
Rake::Task['jenkins:unit'].enhance ['test:foreman_scc_manager', 'foreman_scc_manager:rubocop'] if Rake::Task.task_defined?(:'jenkins:unit')
