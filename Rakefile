require 'bundler/gem_tasks'
require 'rdoc/task'
require 'rspec/core/rake_task'
require 'rdoc/task'

RDoc::Task.new do |rdoc|
  #rdoc.main = "README.rdoc"
  #rdoc.rdoc_files.include("README.rdoc", "lib   /*.rb")
  rdoc.rdoc_dir = 'doc'
  rdoc.rdoc_files.include 'lib'
end


RSpec::Core::RakeTask.new

task :default => :spec
task :test => :spec