version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |gem|
  gem.name        = 'timerizer'
  gem.version     = version
  gem.summary     = 'Rails time helpers... without the Rails'
  gem.description = 'A simple set of Rails-like time helpers'
  gem.authors     = ['Kyle Lacy']
  gem.email       = 'kylelacy@me.com'
  gem.files       = ['lib/timerizer.rb']
  gem.homepage    = 'http://github.com/kylewlacy/timerizer'
end
