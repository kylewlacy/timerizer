require_relative "./lib/timerizer/version"

Gem::Specification.new do |gem|
  gem.name = "timerizer"
  gem.version = Timerizer::VERSION
  gem.license = "MIT"
  gem.summary = "Rails time helpers... without the Rails"
  gem.description = "A simple set of Rails-like time helpers"
  gem.authors = ["Kyle Lacy"]
  gem.email = ["kylelacy@me.com"]
  gem.files = [
    "lib/timerizer.rb",
    "lib/timerizer/core.rb",
    "lib/timerizer/duration.rb",
    "lib/timerizer/wall_clock.rb",
    "lib/timerizer/version.rb"
  ]
  gem.homepage = "http://github.com/kylewlacy/timerizer"

  gem.add_development_dependency "bundler", "~> 1.14"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency "yard", "~> 0.9.9"
end
