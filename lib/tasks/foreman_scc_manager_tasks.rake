require 'rake/testtask'

# Tasks
namespace :foreman_scc_manager do
  namespace :example do
    desc 'Example Task'
    task task: :environment do
      # Task goes here
    end
  end
end

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

namespace :foreman_scc_manager do
  task :rubocop do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_scc_manager) do |task|
        task.patterns = ["#{ForemanSccManager::Engine.root}/app/**/*.rb",
                         "#{ForemanSccManager::Engine.root}/lib/**/*.rb",
                         "#{ForemanSccManager::Engine.root}/test/**/*.rb"]
      end
    rescue StandardError
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_scc_manager'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_scc_manager']

load 'tasks/jenkins.rake'
Rake::Task['jenkins:unit'].enhance ['test:foreman_scc_manager', 'foreman_scc_manager:rubocop'] if Rake::Task.task_defined?(:'jenkins:unit')
