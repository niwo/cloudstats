# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudstack_stats/version'

Gem::Specification.new do |spec|
  spec.name          = "cloudstack_stats"
  spec.version       = CloudstackStats::VERSION
  spec.authors       = ["niwo"]
  spec.email         = ["nik.wolfgramm@gmail.com"]

  spec.summary       = %q{Collect CloudStack stats and feed them to influxdb.}
  spec.description   = %q{Collect project and account statistics from the CloudStack API and feeds them into a influxdb.}
  spec.homepage      = "https://github.com/niwo/cloudtsack_stats"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_runtime_dependency "thor", "~> 0.19"
  spec.add_runtime_dependency "cloudstack_client", "~> 1.4.3"
  spec.add_runtime_dependency "influxdb", "~> 0.3.9"
end
