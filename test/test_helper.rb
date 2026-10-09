# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
require "rails"
require "active_support/time"
Time.zone ||= "UTC"
require "recording_studio_pages"

Dir[File.expand_path("../config/locales/*.yml", __dir__)].each do |path|
  expanded = File.expand_path(path)
  I18n.load_path << expanded unless I18n.load_path.map { |entry| File.expand_path(entry) }.include?(expanded)
end
I18n.backend.load_translations
