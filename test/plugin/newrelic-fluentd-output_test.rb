require "helper"
require 'fluent/plugin/out_newrelic'
require 'webmock/test_unit'
require 'zlib'
require 'newrelic-fluentd-output/version'

class Fluent::Plugin::NewrelicOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  setup do
    Fluent::Test.setup

    @event_time = 12345
    @vortex_success_code = 202
    @vortex_failure_code = 500
    @api_key = "someAccountKey"
    @base_uri = "https://testing-example-collector.com"
    @license_key = 'coolLicense'
    @retry_seconds = 0
    # Don't sleep in tests, to keep tests fast. We have a test for the method that produces the sleep duration between retries.
    @max_delay = 0
    @retries = 3
    @simple_config = %[
        "api_key" #{@api_key}
        "base_uri" #{@base_uri}
        "retries" #{@retries}
        "retry_seconds" #{@retry_seconds}
        "max_delay" #{@max_delay}
    ]
    @license_config = %[
      "license_key" #{@license_key}
      "base_uri" #{@base_uri}
      "retries" #{@retries}
      "retry_seconds" #{@retry_seconds}
      "max_delay" #{@max_delay}
  ]
  end

  sub_test_case 'exposed functionality' do
    test "supports multiple workers" do
      driver = create_driver(@simple_config)

      assert_equal(true, driver.instance.multi_workers_ready?)
    end
  end

  sub_test_case 'configuration' do
    test "requires api_key or license key" do
      no_api_key_config = ""

      assert_raise Fluent::ConfigError.new("'api_key' or 'license_key' parameter is required") do
        create_driver(no_api_key_config)
      end
    end
  end

  sub_test_case "request headers with api key" do
    test "all present" do
      stub_request(:any, @base_uri).to_return(status: @vortex_success_code)

      driver = create_driver(@simple_config)
      driver.run(default_tag: 'test') do
        driver.feed({:message => "Test message"})
      end

      assert_requested(:post, @base_uri,
        headers: {
                "X-Insert-Key" => @api_key,
                "X-Event-Source" => "logs",
                "Content-Encoding" => "gzip",
              })
    end
  end

  sub_test_case "request headers with license key" do
    test "all present" do
      stub_request(:any, @base_uri).to_return(status: @vortex_success_code)

      driver = create_driver(@license_config)
      driver.run(default_tag: 'test') do
        driver.feed({:message => "Test message"})
      end

      assert_requested(:post, @base_uri,
        headers: {
                "X-License-Key" => @license_key,
                "X-Event-Source" => "logs",
                "Content-Encoding" => "gzip",
              })
    end
  end

  sub_test_case "request body" do

    test "message contains plugin information" do
      stub_request(:any, @base_uri).to_return(status: @vortex_success_code)

      driver = create_driver(@simple_config)
      driver.run(default_tag: 'test') do
        driver.feed({:message => "Test message"})
      end

      assert_requested(:post, @base_uri) { |request|
        message = parsed_gzipped_json(request.body)
        message['common']['attributes']['plugin']['type'] == 'fluentd' &&
        message['common']['attributes']['plugin']['version'] == NewrelicFluentdOutput::VERSION }
    end

    test "'timestamp' field is added from event time" do
      stub_request(:any, @base_uri).to_return(status: @vortex_success_code)

      driver = create_driver(@simple_config)
      driver.run(default_tag: 'test') do
        driver.feed(@event_time, {:message => "Test message"})
      end

      assert_requested(:post, @base_uri) { |request|
        message = parsed_gzipped_json(request.body)
        message['logs'][0]['timestamp'] == @event_time }
    end

    test "all other attributes other than message and timestamp are placed in an attributes block" do
      stub_request(:any, @base_uri).to_return(status: @vortex_success_code)

      driver = create_driver(@simple_config)
      driver.run(default_tag: 'test') do
        driver.feed({:message => "Test message", :other => "Other value"})
      end

      assert_requested(:post, @base_uri) { |request|
        message = parsed_gzipped_json(request.body)
        message['logs'][0]['message'] == 'Test message' &&
        message['logs'][0]['attributes']['other'] == 'Other value' }
    end

    test "handles messages with text that is not encodable as UTF-8" do
      stub_request(:any, @base_uri).to_return(status: @vortex_success_code)

      driver = create_driver(@simple_config)
      driver.run(default_tag: 'test') do
        driver.feed({ :message => 'ういじゅん' })
      end

      assert_requested(:post, @base_uri) { |request|
        message = parsed_gzipped_json(request.body)
        message['logs'][0]['message'] == 'ういじゅん' }
    end

    test "handles messages without a 'message' field" do
      stub_request(:any, @base_uri).to_return(status: @vortex_success_code)

      driver = create_driver(@simple_config)
      driver.run(default_tag: 'test') do
        driver.feed({ :other => 'Other value' })
      end

      assert_requested(:post, @base_uri) { |request|
        message = parsed_gzipped_json(request.body)
        message['logs'][0]['attributes']['other'] == 'Other value' }
    end

    # Kubernetes logging puts the message field in the 'log' attribute, we'll use that
    # as the 'message' field if it exists. We do the same in the Fluent Bit output plugin.
    # See https://docs.docker.com/config/containers/logging/fluentd/
    test "Use 'log' as 'message' if it exists" do
      stub_request(:any, @base_uri).to_return(status: @vortex_success_code)

      driver = create_driver(@simple_config)
      driver.run(default_tag: 'test') do
        driver.feed({
                        :log => "Log attribute value",
                        :message => "Should be overwritten by 'log'",
                        :other => "Other value"})
      end

      assert_requested(:post, @base_uri) { |request|
        message = parsed_gzipped_json(request.body)
        message['logs'][0]['log'] == nil &&
            message['logs'][0]['message'] == 'Log attribute value' &&
            message['logs'][0]['attributes']['other'] == 'Other value' }
    end

    test "multiple events" do
      stub_request(:any, @base_uri).to_return(status: @vortex_success_code)

      driver = create_driver(@simple_config)
      driver.run(default_tag: 'test') do
        driver.feed([
          [@event_time, {:message => "Test message 1"}],
          [@event_time, {:message => "Test message 2"}]])
      end

      assert_requested(:post, @base_uri) { |request|
          messages = parsed_gzipped_json(request.body)
          messages['logs'].length == 2 &&
          messages['logs'][0]['message'] == 'Test message 1' &&
          messages['logs'][1]['message'] == 'Test message 2' }
    end
  end

  private

  def gunzip(bytes)
    gz = Zlib::GzipReader.new(StringIO.new(bytes))
    gz.read
  end

  def parsed_gzipped_json(body)
    request = JSON.parse(gunzip(body))
    request[0] # The schema requires an array of log blocks, but this plugin only ever creates a single block
  end

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::NewrelicOutput).configure(conf)
  end
end
