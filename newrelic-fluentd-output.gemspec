# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'newrelic-fluentd-output/version'

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-newrelic"
  spec.version       = NewrelicFluentdOutput::VERSION
  spec.authors       = ["New Relic Logging Team"]
  spec.email         = ["logging-team@newrelic.com"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  end

  spec.summary       = "Sends FluentD events to New Relic"
  spec.homepage      = "https://source.datanerd.us/logging/logstash-output-newrelic"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "fluentd"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "webmock"
end
