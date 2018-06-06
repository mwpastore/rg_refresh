lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rg_refresh/version'

Gem::Specification.new do |spec|
  spec.name          = 'rg_refresh'
  spec.version       = RgRefresh::VERSION
  spec.authors       = ['Mike Pastore']
  spec.email         = ['mike@oobak.org']

  spec.summary       = 'Automated refresh script for the AT&T Residential Gateway bypass'
  spec.homepage      = 'https://github.com/mwpastore/rg_refresh#readme'
  spec.license       = 'MIT'

  spec.files         = %x{git ls-files -z}.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = %w{lib}

  spec.required_ruby_version = '~> 2.2'

  spec.add_dependency 'http-cookie', '~> 1.0.3'
  spec.add_dependency 'mqtt', '~> 0.5.0'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
