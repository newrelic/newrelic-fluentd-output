# New Relict Fluentd output plugin playground

## Starting the environment

To run the environment first go to `./playground` folder:

1. Copy `.env.example` to `.env` and fill your own New Relic API KEY or LICENSE KEY.
2. Run `docker-compose up -d`

Thats it, you should have a running docker with latests new relic output plugin version.

## Writing logs

Since the file `./testlogs/test.log` are mounted as a volume on the docker instance and
is being tailed by fluentd you could write some text to the file and it should be picked
up by fluentd.

This command should write a line on the log file and it will reach new relic in a while.

`echo "Hello world" >> ./testlogs/test.log`

If what you need is send logs every .05s, for example, you can have a big file like
[1mb of text](https://gist.github.com/khaykov/a6105154becce4c0530da38e723c2330) and
use some awk magic to send each line with .05s delay.

`awk '{print $0; system("sleep .05");}' 1mbofdata.txt >> ./testlogs/test.log`

## Troubleshooting

If you need to go inside the container to debug something just run `docker-compose exec fluentd sh`
and you'll be inside the instance. This is a development image so you'll find that you're
logged in as root, this allows you to install the tools you need with `apk`. For example
`apk add vim`.

The plugin is located on `/usr/lib/ruby/gems/2.7.0/gems/fluent-plugin-newrelic-{version}`

## More examples

For more examples, you could adapt the configurations on [examples](../examples/readme.md)
to use them with this playground and test whatever you need.
