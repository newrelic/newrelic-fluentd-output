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
require 'json'
require 'newrelic-fluentd-output/version'

module Fluent
  module Plugin
    class NewrelicOutput < Fluent::Plugin::Output
      class ConnectionFailure < StandardError
      end
      Fluent::Plugin.register_output('newrelic', self)
      helpers :thread

      config_param :api_key, :string
      config_param :base_uri, :string, :default => "https://log-api.newrelic.com/log/v1"
      config_param :retry_seconds, :integer, :default => 5
      config_param :max_delay, :integer, :default => 30
      config_param :retries, :integer, :default => 5
      config_param :concurrent_requests, :integer, :default => 1

      DEFAULT_BUFFER_TYPE = 'memory'.freeze

      config_section :buffer do
        config_set_default :@type, DEFAULT_BUFFER_TYPE
        config_set_default :chunk_keys, ['timestamp']
      end

      define_method('log') {$log} unless method_defined?(:log)

      def configure(conf)
        super

        # create initial sockets hash and socket based on config param
        @end_point = URI.parse(@base_uri)
        @header = {
            'X-Insert-Key' => @api_key,
            'X-Event-Source' => 'logs',
            'Content-Encoding' => 'gzip'
        }.freeze
      end

      def package_record(record, timestamp)
        packaged = {
          'timestamp' => timestamp,
          'attributes' => {}
        }

        if record.has_key?('message')
          message = record['message']
          packaged['attributes'] = packaged['attributes'].merge(maybe_parse_json(message))
        end

        record.each do |key, value|
          if key == 'message'
            packaged['message'] = record['message']
          else
            packaged['attributes'][key] = record[key]
          end
        end
        packaged
      end

      def write(chunk)
        payload = {
          'common' => {
            'attributes' => {
              'plugin' => {
                'type' => 'fluentd',
                'version' => NewrelicFluentdOutput::VERSION,
              }
            }
          },
          'logs' => []
        }
        chunk.msgpack_each do |ts, record|
          next unless record.is_a? Hash
          next if record.empty?
          payload['logs'].push(package_record(record, ts))
        end
        io = StringIO.new
        gzip = Zlib::GzipWriter.new(io)
        gzip << [payload].to_json
        gzip.close
        attempt_send(io.string, 0)
      end

      def should_retry?(attempt)
        attempt < @retries
      end

      def was_successful?(response)
        200 <= response.code.to_i && response.code.to_i < 300
      end

      def sleep_duration(attempt)
        [@max_delay, (2 ** attempt) * @retry_seconds].min
      end

      def attempt_send(payload, attempt)
        sleep sleep_duration(attempt)
        attempt_send(payload, attempt + 1) unless was_successful?(send(payload)) if should_retry?(attempt)
      end

      def send(payload)
        http = Net::HTTP.new(@end_point.host, 443)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        request = Net::HTTP::Post.new(@end_point.request_uri, @header)
        request.body = payload
        http.request(request)
      end

      def maybe_parse_message_json(record)
        if record.has_key?('message')
          message = record['message']
          record = record.merge(maybe_parse_json(message))
        end
        record
      end

      def maybe_parse_json(message)
        begin
          parsed = JSON.parse(message)
          if Hash === parsed
            return parsed
          end
        rescue JSON::ParserError
        end
        return {}
      end
    end
  end
end
