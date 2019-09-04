# fluent-plugin-newrelic

A [Fluentd](https://fluentd.org/) output plugin that sends logs to New Relic

This project is provided AS-IS WITHOUT WARRANTY OR SUPPORT, although you can report issues and contribute to the project here on GitHub.

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
| base_uri | New Relic ingestion endpoint | 'https://log-api.newrelic.com/log/v1' |

### EU plugin configuration

If you are running this plugin in the eu set the `base_uri` to `http://log-api.eu.newrelic.com/log/v1`.

### Fields

* To make Kubernetes log forwarding easier, any `log` field in a log event will be
renamed to `message`, overwriting any `message` field. Kubernetes logs have their messages
in a `log` field, while we want messages in a `message` field.

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
