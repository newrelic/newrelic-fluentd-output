# Developing the plugin

## Developing

* Install Bundler gem: `gem install bundler`
* Install dependencies: `bundle install`
* Write tests and production code!
* Bump version: edit version file `version.rb`
* Run tests: `bundle exec rspec`
* Build the gem: `gem build newrelic-fluentd-output.gemspec`

**NOTE**: Be mindful that if you are using 'match **', that using `log.info` in the plugin can cause an unintended 
Sorcerer's Apprentice Syndrome issue where exponentially larger copies of log messages are sent until the 
td-agent is unloaded. To prevent this, use match tags specific to your source (so use `<match tag_from_your_source>`
instead of `<match **>`), so that your output plugin does not also pick up things that Fluentd logs.

## Testing on MacOS

### Install Fluentd
* `brew cask install td-agent`

### Configure Fluentd
* `sudo vi /etc/td-agent/td-agent.conf`
* Add the following:
```
<source>
  @type tail
  format none
  path /usr/local/var/log/test.log
  tag test
</source>

<match test>
  @type newrelic
  api_key (your-api-key)
</match>
```

### Testing plugin
* Stop Fluentd: `sudo launchctl unload /Library/LaunchDaemons/td-agent.plist`
* Remove previous version: `sudo /opt/td-agent/usr/sbin/td-agent-gem uninstall fluent-plugin-newrelic`
* Add new version: `sudo /opt/td-agent/usr/sbin/td-agent-gem install fluent-plugin-newrelic-<version>.gem`
* Start Fluentd: `sudo launchctl load /Library/LaunchDaemons/td-agent.plist`
* Make sure things start up OK: `tail -f /var/log/td-agent/td-agent.log`
* Cause a change that you've configured Fluentd to pick up: (`echo "FluentdTest" >> /usr/local/var/log/test.log`
* Look in `https://one.newrelic.com/launcher/logger.log-launcher` for your log message ("FluentdTest")
