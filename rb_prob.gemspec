
spec = Gem::Specification.new do |s|
  s.name        = 'rb_prob'
  s.version     = '0.0.2'
  s.licenses    = 'BDS3'
  s.summary     = 'monadic probabilistic programming for ruby'
  s.description = 'monad programming programming library for ruby. for examples see github repository: http://github.com/urso/rb_prob'
  s.files       = Dir['lib/**/*.rb'] + Dir['examples/**/*.rb'] + ['LICENSE']
  s.has_rdoc    = true
  s.author      = 'Steffen Siering'
  s.email       = 'steffen <dot> siering -> gmail <dot> com'
  s.homepage    = 'http://github.com/urso/rb_prob'
end

