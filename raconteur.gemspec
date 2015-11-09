# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'raconteur/version'

Gem::Specification.new do |spec|
  spec.name          = "raconteur"
  spec.version       = Raconteur::VERSION
  spec.authors       = ["Jamie Appleseed"]
  spec.email         = ["jamieappleseed@gmail.com"]

  spec.summary       = %q{Custom text tag parsing}
  spec.description   = %q{Define custom text tags and have Raconteur parse them as per your specifications}
  spec.homepage      = "https://github.com/JamieAppleseed/raconteur"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
  spec.add_development_dependency "kramdown"

end
