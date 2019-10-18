require "bundler"
Bundler::GemHelper.install_tasks

require "rake/testtask"
require 'ci/reporter/rake/test_unit'

Rake::TestTask.new(:test) do |t|
  t.libs.push("lib", "test")
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
  t.warning = true
end

namespace :ci do
  task :all => ['ci:setup:testunit', 'test']
end

task default: ["ci:all"]

