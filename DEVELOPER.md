# Developing the plugin

## Developing

* Install Bundler gem: `gem install bundler`
* Install dependencies: `bundle install`
* Write tests and production code!
* Bump version: edit version file `version.rb`
* Run tests: `bundle exec rspec`
* Build the gem: `gem build newrelic-fluentd-output.gemspec`

**NOTE**: Be mindful that using `log.info` in the plugin causes an unintended Sorcerer's Apprentice Syndrome style bug where exponentially larger copies of log messages are sent until the td-agent is unloaded. Super weird, but now you know.

## Pushing changes to the public repo
After updating the New Relic repo with changes, changes will need to be pushed to the public GitHub repo at: https://github.com/newrelic/newrelic-fluentd-output

* `git remote add public git@github.com:newrelic/newrelic-fluentd-output.git`
* `git push public master:name-of-branch-to-create`
* Create a PR from that branch in https://github.com/newrelic/newrelic-fluentd-output
* Get the PR reviewed, merged, and delete the branch!

# Testing it with a local Fluentd install

* Remove previous version: `td-agent-gem uninstall fluent-plugin-newrelic`
* Add new version: `td-agent-gem install fluent-plugin-newrelic-<version>.gem`
* Restart Fluentd
* Cause a change that you've configured Fluentd to pick up (for instance, append to a file you're having it monitor)
* Look in `https://staging-one.newrelic.com/launcher/logger.log-launcher` for your log message

# Push changes to RubyGems
After updating the source code and gem version in `version.rb`, push the changes to RubyGems. Note, you must be a gem owner to publish changes on [RubyGems.org](https://rubygems.org/profiles/NR-LOGGING)

* Build the gem: `gem build newrelic-fluentd-output.gemspec`
* Publish the gem: `gem push --host https://rubygems.org fluent-plugin-newrelic-<VERSION>.gem` with the updated version (ex: `gem push --host https://rubygems.org fluent-plugin-newrelic-0.2.2.gem`)
