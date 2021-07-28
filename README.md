[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# fluent-plugin-newrelic

A [Fluentd](https://fluentd.org/) output plugin that sends logs to New Relic

This project is provided AS-IS WITHOUT WARRANTY OR SUPPORT, although you can report issues and contribute to the project here on GitHub.

## Examples

Please see the [examples](examples/) directory for ways to build a Docker image with the New Relic output plugin and other configuration types
that could be useful in your environment.

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

This plugin must be configured with either a New Relic API Insert key, or a New Relic License key.
If both types of keys are specified, the API Insert key will take precedence.

To specify an API Insert key, either set the `api_key` property in the configuration, or set the `NEW_RELIC_API_KEY` environment variable. If both are specified, the configuration property will take precedence.

To specify a license key, either set the `license_key` property in the configuration, or set the `NEW_RELIC_LICENSE_KEY` environment variable. If both are specified, the configuration property will take precedence.

### Optional plugin configuration

| Property | Description | Default value |
|---|---|---|
| base_uri | New Relic ingestion endpoint | `https://log-api.newrelic.com/log/v1` |

### EU plugin configuration

If you are running this plugin in the eu set the `base_uri` to `https://log-api.eu.newrelic.com/log/v1`.

### Fields

* To make Kubernetes log forwarding easier, any `log` field in a log event will be
renamed to `message`, overwriting any `message` field. Kubernetes logs have their messages
in a `log` field, while we want messages in a `message` field.

### Example

Add one of the following blocks to your Fluentd config file (with your specific key), then restart Fluentd.

#### Using Insights Inserts Key

Example using Insights Insert key:

```rb
<match **>
  @type newrelic
  api_key <NEW_RELIC_INSIGHTS_INSERT_KEY>
</match>
```

Getting your New Relic Insights Insert key:
`https://insights.newrelic.com/accounts/<ACCOUNT_ID>/manage/api_keys`

#### Using License Key

Example using License key:

```rb
<match **>
  @type newrelic
  license_key <NEW_RELIC_LICENSE_KEY>
</match>
```

Getting your New Relic license key:
`https://rpm.newrelic.com/accounts/<ACCOUNT_ID>`

## Playground

To provide a sandbox environment where you can play with the plugin while development or testing
we've added a docker-compose environment that would help to run fluend with the plugin and send
some logs. [More info](playground/README.md)

## Community

New Relic hosts and moderates an online forum where customers can interact with New Relic employees as well as other customers to get help and share best practices. Like all official New Relic open source projects, there's a related Community topic in the New Relic Explorers Hub: [Log forwarding](https://discuss.newrelic.com/tag/log-forwarding)


**A note about vulnerabilities**

As noted in our [security policy](../../security/policy), New Relic is committed to the privacy and security of our customers and their data. We believe that providing coordinated disclosure by security researchers and engaging with the security community are important means to achieve our security goals.

If you believe you have found a security vulnerability in this project or any of New Relic's products or websites, we welcome and greatly appreciate you reporting it to New Relic through [HackerOne](https://hackerone.com/newrelic).

If you would like to contribute to this project, **please create a branch directly in this repository** and review [these guidelines](https://opensource.newrelic.com/code-of-conduct/). 

## License

newrelic-fluentd-output is licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.


## Copyright

* Copyright(c) 2019 - New Relic
* License
  * Apache License, Version 2.0
