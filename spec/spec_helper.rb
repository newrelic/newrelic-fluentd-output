$LOAD_PATH.unshift(File.expand_path("../../", __FILE__))
# require "test-unit"
require "fluent/test"
require "fluent/test/driver/output"
require "fluent/test/helpers"
require 'fluent/plugin/out_newrelic'

Test::Unit::TestCase.include(Fluent::Test::Helpers)
Test::Unit::TestCase.extend(Fluent::Test::Helpers)
# Test::Unit.run = true if defined?(Test::Unit) && Test::Unit.respond_to?(:run=)
# Test::Unit::AutoRunner.need_auto_run = false if defined?(Test::Unit::AutoRunner)
