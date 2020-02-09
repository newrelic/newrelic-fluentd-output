# Fluentd -> New Relic Examples

## Creating a Docker Image

Using [Fluentd](https://www.fluentd.org/) as an image makes it simple to deploy a quick input logging solution for functions such as [Syslogs](https://docs.fluentd.org/input/syslog), [HTTP](https://docs.fluentd.org/input/http), custom [UDP](https://docs.fluentd.org/input/udp) and [TCP](https://docs.fluentd.org/input/tcp) use cases, [SNMP](https://github.com/iij/fluent-plugin-snmp), along with many other functions. The [Fluentd](https://www.fluentd.org/) team has put together a great [set of documents](https://docs.fluentd.org/container-deployment) to help you get their basic configuration setup. After that, you will want to get your logs flowing into [New Relic Logs](https://docs.newrelic.com/docs/logs/new-relic-logs/get-started/introduction-new-relic-logs) to create alerts and monitor your systems.

If you are able to use the Fluentd image directly, it is really simple build on that image and add the New Relic Fluetd Output Plugin. The below set of steps assumes you have some basic understanding of building a Docker image.

### Steps

#### 1. Create a `Dockerfile`

It doesn't take much to get the New Relic Output Plugin into a docker image.

```yaml
FROM fluent/fluentd:v1.9.1-1.0

USER root

RUN fluent-gem install fluent-plugin-newrelic
```

#### 2. Build the Image

The build process is simple and will register a newly created image in your local Docker repository. If you want to use this image for multiple machines, you will need to publish the image to a location you can access.

```bash
docker build --tag nr-fluent:latest nri-fluentd .
```
