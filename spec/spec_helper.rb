require "bundler/setup"
require "timerizer"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expose_dsl_globally = false

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
