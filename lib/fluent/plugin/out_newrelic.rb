#
# Copyright 2018 - New Relic
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fluent/plugin/output'
require 'net/http'
require 'uri'
require 'zlib'
require 'newrelic-fluentd-output/version'
require 'yajl'

module Fluent
  module Plugin
    class NewrelicOutput < Fluent::Plugin::Output
      class ConnectionFailure < StandardError
      end
      Fluent::Plugin.register_output('newrelic', self)
      helpers :thread

      config_param :api_key, :string, :default => nil
      config_param :base_uri, :string, :default => "https://log-api.newrelic.com/log/v1"
      config_param :license_key, :string, :default => nil

      DEFAULT_BUFFER_TYPE = 'memory'.freeze
      DEFAULT_TIMEKEY = 5
      DEFAULT_TIMEKEY_WAIT = 0
      MAX_PAYLOAD_SIZE = 1000000 # bytes

      config_section :buffer do
        config_set_default :@type, DEFAULT_BUFFER_TYPE
        config_set_default :chunk_keys, ['time']
        config_set_default :timekey, DEFAULT_TIMEKEY
        config_set_default :timekey_wait, DEFAULT_TIMEKEY_WAIT
      end

      define_method('log') {$log} unless method_defined?(:log)

      # This tells Fluentd that it can run this output plugin in multiple workers.
      # Our plugin has no interactions with other processes
      def multi_workers_ready?
        true
      end

      def configure(conf)
        super

        @api_key ||= ENV["NEW_RELIC_API_KEY"]
        @license_key ||= ENV["NEW_RELIC_LICENSE_KEY"]
        if @api_key.nil? && @license_key.nil?
          raise Fluent::ConfigError.new("'api_key' or 'license_key' parameter is required")
        end

        # create initial sockets hash and socket based on config param
        @end_point = URI.parse(@base_uri)
        auth = {
          @api_key.nil? ? 'X-License-Key' : 'X-Insert-Key' =>
          @api_key.nil? ? @license_key : @api_key
        }
        @header = {
            'X-Event-Source' => 'logs',
            'Content-Encoding' => 'gzip'
        }.merge(auth)
        .freeze
      end

      def package_record(record, timestamp)
        packaged = {
          'timestamp' => resolveTimestamp(record['timestamp'], timestamp),
          # non-intrinsic attributes get put into 'attributes'
          'attributes' => record
        }

        # intrinsic attributes go at the top level
        if record.has_key?('message')
          packaged['message'] = record['message']
          packaged['attributes'].delete('message')
        end

        # Kubernetes logging puts the message field in the 'log' attribute, we'll use that
        # as the 'message' field if it exists. We do the same in the Fluent Bit output plugin.
        # See https://docs.docker.com/config/containers/logging/fluentd/
        if record.has_key?('log')
          packaged['message'] = record['log']
          packaged['attributes'].delete('log')
        end

        packaged
      end

      def write(chunk)
        logs = []
        chunk.msgpack_each do |ts, record|
          next unless record.is_a? Hash
          next if record.empty?
          logs.push(package_record(record, ts))
        end


        payloads = get_compressed_payloads(logs)
        payloads.each { |payload| send_payload(payload) }
      end

      def handle_response(response)
        if !(200 <= response.code.to_i && response.code.to_i < 300)
          log.error("Response was " + response.code + " " + response.body)
        end
      end

      def send_payload(payload)
        http = Net::HTTP.new(@end_point.host, 443)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        request = Net::HTTP::Post.new(@end_point.request_uri, @header)
        request.body = payload
        handle_response(http.request(request))
      end

      private

      def get_compressed_payloads(logs)
        return [] if logs.length == 0

        payload = create_payload(logs)
        compressed_payload = compress(payload)

        if compressed_payload.bytesize <= MAX_PAYLOAD_SIZE
          return [compressed_payload]
        end

        compressed_payload_bytesize = compressed_payload.bytesize
        compressed_payload = nil # Free for GC

        if logs.length > 1 # we can split
          # let's split logs array by half, and try to create payloads again
          midpoint = logs.length / 2
          first_half = get_compressed_payloads(logs.slice(0, midpoint))
          second_half = get_compressed_payloads(logs.slice(midpoint, logs.length))
          return first_half + second_half
        else
          log.error("Can't compress record below required maximum packet size and it will be discarded. " +
                      "Record timestamp: #{logs[0]['timestamp']}. Compressed size: #{compressed_payload_bytesize} bytes. Uncompressed size: #{payload.to_json.bytesize} bytes.")
          return []
        end
      end

      def create_payload(logs)
        {
          'common' => {
            'attributes' => {
              'plugin' => {
                'type' => 'fluentd',
                'version' => NewrelicFluentdOutput::VERSION,
              }
            }
          },
          'logs' => logs
        }
      end

      def compress(payload)
        io = StringIO.new
        gzip = Zlib::GzipWriter.new(io)

        # Fluentd can run with a version of Ruby (2.1.0) whose to_json method doesn't support non-ASCII characters.
        # So we use Yajl, which can handle all Unicode characters. Apparently this library is what Fluentd uses
        # internally, so it is installed by default with td-agent.
        # See https://github.com/fluent/fluentd/issues/215
        gzip << Yajl.dump([payload])
        gzip.close
        io.string
      end

      def resolveTimestamp(recordTimestamp, fluentdTimestamp)
        if recordTimestamp
          recordTimestamp
        else
          if defined? fluentdTimestamp.nsec
            fluentdTimestamp = fluentdTimestamp * 1000 + fluentdTimestamp.nsec / 1_000_000
          end
          fluentdTimestamp
        end
      end
    end
  end
end
