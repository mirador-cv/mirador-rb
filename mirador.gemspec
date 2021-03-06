# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mirador/version'

Gem::Specification.new do |gem|
  gem.name          = "mirador"
  gem.version       = Mirador::VERSION
  gem.authors       = ["Nick Jacob"]
  gem.email         = ["nick@mirador.im"]
  gem.description   = %q{Interface to the Mirador Image Moderation API}
  gem.summary       = %q{Simple interface to mirador API }
  gem.homepage      = "http://mirador-cv.github.io/mirador-rb"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_runtime_dependency 'httparty', '~> 0.13.0', '>= 0.13.0'
end
