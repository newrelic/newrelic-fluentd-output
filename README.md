# fluent-plugin-newrelic

A [Fluentd](https://fluentd.org/) output plugin that sends logs to New Relic

## Prerequisites

Fluentd >= v1.0

## Installation
Add the plugin to your fluentd agent:

`fluent-gem install fluent-plugin-newrelic`

If you are using td-agent:

`td-agent-gem install fluent-plugin-newrelic`

For more info, review [Fluentd's official documentation](https://docs.fluentd.org/deployment/plugin-management).

## Configuration

### Required plugin configuration

| Property | Description |
|---|---|
| api_key | your New Relic API Insert key |

### Optional plugin configuration

| Property | Description | Default value |
|---|---|---|
| concurrent_requests | The number of threads to make requests from | 1 |
| retries | The maximum number of times to retry a failed request, exponentially increasing delay between each retry | 5 |
| retry_seconds | The inital delay between retries, in seconds | 5 |
| max_delay | The maximum delay between retries, in seconds | 30 |
| base_uri | New Relic ingestion endpoint | 'https://log-api.newrelic.com/log/v1' |

### Example

Add the following block to your Fluentd config file (with your specific New Relic Insights Insert key), then restart Fluentd.

Example:
```rb
<match **>
  @type newrelic
  api_key <NEW_RELIC_INSIGHTS_INSERT_KEY>
</match>
```

Getting your New Relic Insights Insert key:
`https://insights.newrelic.com/accounts/<ACCOUNT_ID>/manage/api_keys`

## Copyright

* Copyright(c) 2019 - New Relic
* License
  * Apache License, Version 2.0
