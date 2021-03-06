# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fast_serializer"
  spec.version       = File.read(File.expand_path("../VERSION", __FILE__)).chomp
  spec.authors       = ["We Heart It", "Brian Durand"]
  spec.email         = ["dev@weheartit.com", "bbdurand@gmail.com"]
  spec.description   = %q{Super fast object serialization for API's combining a simple DSL with many optimizations under the hood.}
  spec.summary       = %q{Super fast object serialization for API's.}
  spec.homepage      = "https://github.com/weheartit/fast_serializer"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~>1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~>3.0"
end
