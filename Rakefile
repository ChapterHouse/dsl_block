require 'bundler/gem_tasks'
require 'rdoc/task'
require 'rspec/core/rake_task'
require 'rdoc/task'

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.main = 'DslBlock.html'
  rdoc.rdoc_files.include 'lib'
end


RSpec::Core::RakeTask.new

task :default => :spec
task :test => :spec