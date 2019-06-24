# Developing the plugin

## Developing

* Install Bundler gem: `gem install bundler`
* Install dependencies: `bundle install`
* Write tests and production code!
* Bump version: edit version file `version.rb`
* Run tests: `bundle exec rspec`
* Build the gem: `gem build newrelic-fluentd-output.gemspec`

**NOTE**: Be mindful that using `log.info` in the plugin causes an unintended Sorcerer's Apprentice Syndrome style bug where exponentially larger copies of log messages are sent until the td-agent is unloaded. Super weird, but now you know.


# Testing it with a local Fluentd install

* Remove previous version: `td-agent-gem uninstall fluent-plugin-newrelic`
* Add new version: `td-agent-gem install fluent-plugin-newrelic-<version>.gem`
* Restart Fluentd
* Cause a change that you've configured Fluentd to pick up (for instance, append to a file you're having it monitor)
* Look in `https://staging-one.newrelic.com/launcher/logger.log-launcher` for your log message

# Push changes to RubyGems
After updating the source code and gem version in `version.rb`, push the changes to RubyGems. Note, you must be a gem owner to publish changes on [RubyGems.org](https://rubygems.org/profiles/NR-LOGGING)

* Build the gem: `gem build newrelic-fluentd-output.gemspec`
* Publish the gem: `gem push fluent-plugin-newrelic-<VERSION>.gem` with the updated version (ex: `gem push fluent-plugin-newrelic-0.2.2.gem`)
