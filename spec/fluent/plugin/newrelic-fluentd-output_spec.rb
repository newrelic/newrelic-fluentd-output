require 'spec_helper'
require 'webmock/test_unit'
require 'zlib'
require 'newrelic-fluentd-output/version'

class Fluent::Plugin::NewrelicOutputTest < Test::Unit::TestCase


  setup do
    Fluent::Test.setup

    @event_time = 12345
    @vortex_success_code = 202
    @vortex_failure_code = 500
    @api_key = "someAccountKey"
    @base_uri = "https://testing-example-collector.com"
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
  end

  sub_test_case 'configuration' do
    test "requires api_key" do
      no_api_key_config = ""

      assert_raise Fluent::ConfigError.new("'api_key' parameter is required") do
        create_driver(no_api_key_config)
      end
    end
  end

  sub_test_case "request headers" do
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

    test "'timestamp' field is added" do
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

    sub_test_case "JSON parsing" do

      test "JSON object 'message' field is parsed, removed, and its data merged as attributes" do
        stub_request(:any, @base_uri).to_return(status: @vortex_success_code)
        message_json = '{ "in-json-1": "1", "in-json-2": "2", "sub-object": {"in-json-3": "3"} }'

        driver = create_driver(@simple_config)
        driver.run(default_tag: 'test') do
          driver.feed({ :message => message_json, :other => "Other value" })
        end

        assert_requested(:post, @base_uri) { |request|
            message = parsed_gzipped_json(request.body)
            message['logs'][0]['attributes']['in-json-1'] == '1' &&
            message['logs'][0]['attributes']['in-json-2'] == '2' &&
            message['logs'][0]['attributes']['sub-object'] == {"in-json-3" => "3"} &&
            message['logs'][0]['attributes']['other'] == 'Other value' }
      end

      test "JSON array 'message' field is not parsed, left as is" do
        stub_request(:any, @base_uri).to_return(status: @vortex_success_code)
        message_json_array = '[{ "in-json-1": "1", "in-json-2": "2", "sub-object": {"in-json-3": "3"} }]'

        driver = create_driver(@simple_config)
        driver.run(default_tag: 'test') do
          driver.feed({ :message => message_json_array, :other => "Other value" })
        end

        assert_requested(:post, @base_uri) { |request|
            message = parsed_gzipped_json(request.body)
            message['logs'][0]['message'] == message_json_array &&
            message['logs'][0]['attributes']['other'] == 'Other value' }
      end

      test "JSON string 'message' field is not parsed, left as is" do
        stub_request(:any, @base_uri).to_return(status: @vortex_success_code)
        message_json_string = '"I can be parsed as JSON"'

        driver = create_driver(@simple_config)
        driver.run(default_tag: 'test') do
          driver.feed({ :message => message_json_string, :other => "Other value" })
        end

        assert_requested(:post, @base_uri) { |request|
            message = parsed_gzipped_json(request.body)
            message['logs'][0]['message'] == message_json_string &&
            message['logs'][0]['attributes']['other'] == 'Other value' }
      end

      test "other JSON fields are not parsed" do
        stub_request(:any, @base_uri).to_return(status: @vortex_success_code)
        other_json = '{ "key": "value" }'

        driver = create_driver(@simple_config)
        driver.run(default_tag: 'test') do
          driver.feed({ :message => "Test message", :other => other_json })
        end

        assert_requested(:post, @base_uri) { |request|
            message = parsed_gzipped_json(request.body)
            message['logs'][0]['message'] == 'Test message' &&
            message['logs'][0]['attributes']['other'] == other_json }
      end
    end


    sub_test_case "retry" do
      test "sleep periods double each time up to max time" do

        # Create a new plugin with this specific config that has longer retry sleep
        # configuration than we normally want
        driver = Fluent::Plugin::NewrelicOutput.new()
        # Use non-trivial times -- they can be big, since this test doesn't do any sleeping, just 
        # tests the sleep duration
        driver.retry_seconds = 5
        driver.max_delay = 60

        assert_equal(5, driver.sleep_duration(0))
        assert_equal(10, driver.sleep_duration(1))
        assert_equal(20, driver.sleep_duration(2))
        assert_equal(40, driver.sleep_duration(3))
        assert_equal(60, driver.sleep_duration(4))
        assert_equal(60, driver.sleep_duration(5)) # Never gets bigger than this
      end

      test "first call fails, should retry" do
        stub_request(:any, @base_uri)
          .to_return(status: @vortex_failure_code)
          .to_return(status: @vortex_success_code)

        driver = create_driver(@simple_config)
        driver.run(default_tag: 'test') do
          driver.feed({:message => "Test message"})
        end

        assert_requested(:post, @base_uri,  times: 2)
      end

      test "first two calls fail, should retry" do
        stub_request(:any, @base_uri)
          .to_return(status: @vortex_failure_code)
          .to_return(status: @vortex_failure_code)
          .to_return(status: @vortex_success_code)

        driver = create_driver(@simple_config)
        driver.run(default_tag: 'test') do
          driver.feed({:message => "Test message"})
        end

        assert_requested(:post, @base_uri,  times: 3)
      end

      test "all calls fails, should stop retrying at some point" do
        stub_request(:any, @base_uri)
          .to_return(status: @vortex_failure_code)

        driver = create_driver(@simple_config)
        driver.run(default_tag: 'test') do
          driver.feed({:message => "Test message"})
        end

        assert_requested(:post, @base_uri,  times: @retries)
      end
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
