# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'newrelic-fluentd-output/version'

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-newrelic"
  spec.version       = NewrelicFluentdOutput::VERSION
  spec.authors       = ["New Relic Logging Team"]
  spec.licenses      = ['Apache-2.0']
  spec.email         = ["logging-team@newrelic.com"]

  spec.summary       = "Sends FluentD events to New Relic"
  spec.homepage      = "https://github.com/newrelic/newrelic-fluentd-output"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "fluentd", ">=1.0.0"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "rspec_junit_formatter"
end
