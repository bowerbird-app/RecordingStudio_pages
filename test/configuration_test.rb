# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioPages::Configuration.new
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(homepage_path: "/welcome", register_built_in_sections: false)

    assert_equal "/welcome", @configuration.homepage_path
    assert_equal false, @configuration.register_built_in_sections
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", homepage_path: "/ok")

    refute_respond_to @configuration, :unknown_key
    assert_equal "/ok", @configuration.homepage_path
  end

  def test_merge_with_non_enumerable_is_noop
    original = @configuration.to_h

    @configuration.merge!(nil)

    assert_equal original.fetch(:homepage_path), @configuration.homepage_path
    assert_equal original.fetch(:register_built_in_sections), @configuration.register_built_in_sections
  end

  def test_theme_falls_back_to_rounded
    assert_equal "rounded", RecordingStudioPages.normalize_theme(nil)
    assert_equal "rounded", RecordingStudioPages.normalize_theme("")
    assert_equal "rounded", RecordingStudioPages.normalize_theme("???")
  end

  def test_theme_normalizes_host_flatpack_names
    assert_equal "rounded", RecordingStudioPages.normalize_theme(:rounded)
    assert_equal "featured-in", RecordingStudioPages.normalize_theme(:featured_in)
    assert_equal "ocean", RecordingStudioPages.normalize_theme("Ocean")
  end

  def test_initialize_uses_defaults
    configuration = RecordingStudioPages::Configuration.new

    assert_equal %w[Workspace Folder], configuration.page_parent_types
    assert_equal "/", configuration.homepage_path
    assert_equal true, configuration.register_built_in_sections
    assert_instance_of RecordingStudio::Hooks, configuration.hooks
  end

  def test_merge_accepts_string_keys
    @configuration.merge!("homepage_path" => "/home", "register_built_in_sections" => false)

    assert_equal "/home", @configuration.homepage_path
    assert_equal false, @configuration.register_built_in_sections
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudioPages.configure

    assert_kind_of RecordingStudioPages::Configuration, RecordingStudioPages.configuration
  end

  def test_page_parent_helpers_use_configuration
    original = RecordingStudioPages.instance_variable_get(:@configuration)
    RecordingStudioPages.instance_variable_set(:@configuration, RecordingStudioPages::Configuration.new)
    RecordingStudioPages.configure do |config|
      config.page_parent_types = %w[Workspace]
      config.homepage_path = "/welcome"
    end
    workspace = Struct.new(:recordable_type).new("Workspace")
    folder = Struct.new(:recordable_type).new("Folder")

    assert_equal %w[Workspace], RecordingStudioPages.page_parent_types
    assert_equal "/welcome", RecordingStudioPages.homepage_path
    assert RecordingStudioPages.page_parent?(workspace)
    refute RecordingStudioPages.page_parent?(folder)
    refute RecordingStudioPages.page_parent?(nil)
  ensure
    RecordingStudioPages.instance_variable_set(:@configuration, original)
  end
end
