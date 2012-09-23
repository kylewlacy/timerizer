require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
task :default => :spec

task :make do
  puts `gem build #{Dir['*.gemspec'].first}`
end
