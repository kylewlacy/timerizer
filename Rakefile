require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |rspec|
  rspec.rspec_opts = '--no-color'
end

task :default => :spec

task :make do
  puts `gem build #{Dir['*.gemspec'].first}`
end
