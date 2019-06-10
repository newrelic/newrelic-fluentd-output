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
* Look in `https://wanda-ui.staging-service.newrelic.com/launcher/logger.log-launcher` for your log message

# Deploying to Gemfury

After merging to master you must also push the code to Gemfury, which is where customers will get our gem from.
* Get the version you just merged to master in Github
  * `git checkout master`
  * `git pull`
* Push the new master to Gemfury
   * Add Gemfury as remote (only needs to be done once): `git remote add fury https://<your-gemfury-username>@git.fury.io/nrsf/newrelic-fluentd-output.git`
   * Push the new commits to Gemfury: `git push fury master`
   * For the password, use the "Personal full access token" seen here https://manage.fury.io/manage/newrelic/tokens/shared
   * Make sure you see your new code show up here: `https://manage.fury.io/dashboard/nrsf`