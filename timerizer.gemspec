require_relative "./lib/timerizer/version"

Gem::Specification.new do |gem|
  gem.name = "timerizer"
  gem.version = Timerizer::VERSION
  gem.license = "MIT"
  gem.summary = "Rails time helpers... without the Rails"
  gem.description = "A simple set of Rails-like time helpers"
  gem.authors = ["Kyle Lacy"]
  gem.email = ["kylelacy@me.com"]
  gem.files = Dir.glob('lib/**/*.rb')
  gem.homepage = "http://github.com/kylewlacy/timerizer"

  gem.add_development_dependency "bundler", "~> 2.0"
  gem.add_development_dependency "rake", "~> 12.3"
  gem.add_development_dependency "rspec", "~> 3.8"
  gem.add_development_dependency "yard", "~> 0.9.20"
end
