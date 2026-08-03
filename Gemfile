# Pin fastlane so a developer's machine and CI run byte-identical tooling.
# Always invoke through `bundle exec` — a globally installed fastlane will drift.

source "https://rubygems.org"

gem "fastlane", "~> 2.237"

# fastlane resolves its own plugins through this file.
plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
