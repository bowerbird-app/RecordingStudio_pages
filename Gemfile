# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_pages.gemspec
gemspec

# recording_studio and FlatPack are not published to RubyGems; resolve from GitHub.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.341"
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v6.5.0"

gem "devise"
gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "json", ">= 2.19.9", "< 3"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", "~> 1.81.0", require: false
  gem "rubocop-rails", require: false
end
