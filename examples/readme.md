# Fluentd -> New Relic Examples

## Creating a Docker Image

Using [Fluentd](https://www.fluentd.org/) as an image makes it simple to deploy a quick input logging solution for functions such as [Syslogs](https://docs.fluentd.org/input/syslog), [HTTP](https://docs.fluentd.org/input/http), custom [UDP](https://docs.fluentd.org/input/udp) and [TCP](https://docs.fluentd.org/input/tcp) use cases, [SNMP](https://github.com/iij/fluent-plugin-snmp), along with many other functions. The [Fluentd](https://www.fluentd.org/) team has put together a great [set of documents](https://docs.fluentd.org/container-deployment) to help you get their basic configuration setup. After that, you will want to get your logs flowing into [New Relic Logs](https://docs.newrelic.com/docs/logs/new-relic-logs/get-started/introduction-new-relic-logs) to create alerts and monitor your systems.

If you are able to use the Fluentd image directly, it is really simple build on that image and add the New Relic Fluetd Output Plugin. The below set of steps assumes you have some basic understanding of building a Docker image.

### Steps

#### 1. Create a `Dockerfile`

It doesn't take much to get the New Relic Output Plugin into a docker image. Here is a good example from Docker on how best to create an image, [LINK](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/).

```yaml
FROM fluent/fluentd:v1.9.1-1.0

USER root

RUN fluent-gem install fluent-plugin-newrelic
```

#### 2. Build the Image

The build process is simple and will register a newly created image in your local Docker repository. If you want to use this image for multiple machines, you will need to publish the image to a location you can access.

```bash
# Run this command in the same directory as the Docker file or point to its location
docker build --tag nr-fluent:latest nri-fluentd .

# Run this command to verify the image was created
docker image ls

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nr-fluent           latest              70c388b63afc        1 minute ago        44.9MB
```

#### 3. Run the Docker Image

The next steps assume that you have already created a `fluentd.conf` file with is ready to being monitoring. If you haven't, you must do so before you continue.

In the following example can be used if you are going to run a syslog server on the image.

```bash
# Notice that the syntax for exposing the UDP port is a bit different
# In testing, it appeared that trying to map the UDP port to from a different one configured in the Fluentd config file didn't work as expected
docker run -d --name "syslog" -p 0.0.0.0:5140:5140/udp -p 0.0.0.0:5142:5142/udp -v /etc/fluentd:/fluentd/etc -e FLUENTD_CONF=fluentd.conf nr-fluent:latest
```
