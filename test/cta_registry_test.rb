# frozen_string_literal: true

require "test_helper"

class CtaRegistryTest < Minitest::Test
  def setup
    RecordingStudioPages.reset!
  end

  def teardown
    RecordingStudioPages.reset!
    RecordingStudioPages::BuiltIns.register!
  end

  def test_register_and_lookup
    RecordingStudioPages.register_cta(
      key: :waitlist,
      name: "Waitlist",
      component: "RecordingStudioPages::Ctas::ButtonComponent",
      fields: { placeholder: :string }
    )

    definition = RecordingStudioPages.cta(:waitlist)

    assert RecordingStudioPages.cta?(:waitlist)
    assert_equal "waitlist", definition.key
    assert_equal "Waitlist", definition.name
    assert_includes RecordingStudioPages.ctas.map(&:key), "waitlist"
  end

  def test_duplicate_registration_raises
    attributes = {
      key: :waitlist,
      name: "Waitlist",
      component: "RecordingStudioPages::Ctas::ButtonComponent",
      source: "host"
    }
    RecordingStudioPages.register_cta(**attributes)

    error = assert_raises(RecordingStudioPages::DuplicateRegistration) do
      RecordingStudioPages.register_cta(**attributes)
    end
    assert_includes error.message, "waitlist"
    assert_includes error.message, "host"
  end

  def test_unknown_cta_fetch_raises_and_find_is_nil
    assert_nil RecordingStudioPages.find_cta(:missing)
    refute RecordingStudioPages.cta?(:missing)
    assert_raises(RecordingStudioPages::UnknownCtaType) { RecordingStudioPages.cta(:missing) }
  end

  def test_built_in_button_cta_is_registered
    RecordingStudioPages::BuiltIns.register!

    assert RecordingStudioPages.cta?(:button)
    button = RecordingStudioPages.cta(:button)

    assert_equal "Button", button.name
    assert_equal "string", button.fields.catalog[:text][:type]
    assert_equal "url", button.fields.catalog[:url][:type]
  end

  def test_cta_renderer_skips_blank_and_unknown_types
    view = Object.new
    view.define_singleton_method(:render) { |_component| raise "should not render" }

    assert_nil RecordingStudioPages::CtaRenderer.call(view, nil)
    assert_nil RecordingStudioPages::CtaRenderer.call(view, { "type" => "" })
    assert_nil RecordingStudioPages::CtaRenderer.call(view, { "type" => "missing_widget" })
  end

  def test_cta_renderer_skips_when_the_component_raises
    component = Class.new do
      def initialize(cta:); end
    end
    RecordingStudioPages.register_cta(
      key: :boom,
      name: "Boom",
      component: component
    )
    view = Object.new
    view.define_singleton_method(:render) { |_component| raise "boom" }
    warnings = []
    logger = Object.new
    logger.define_singleton_method(:warn) { |message| warnings << message.to_s }
    previous_logger = Rails.logger
    Rails.logger = logger

    assert_nil RecordingStudioPages::CtaRenderer.call(view, { "type" => "boom" })
    assert(warnings.any? { |message| message.include?("boom") })
  ensure
    Rails.logger = previous_logger
  end

  def test_cta_renderer_passes_align_only_when_the_component_accepts_it
    received = []
    aligned = Class.new do
      define_method(:initialize) do |cta:, align: :center|
        @cta = cta
        @align = align
      end
    end
    plain = Class.new do
      define_method(:initialize) do |cta:|
        @cta = cta
      end
    end
    RecordingStudioPages.register_cta(key: :aligned, name: "Aligned", component: aligned)
    RecordingStudioPages.register_cta(key: :plain, name: "Plain", component: plain)

    view = Object.new
    view.define_singleton_method(:render) do |component|
      received << component
      "ok"
    end

    RecordingStudioPages::CtaRenderer.call(view, { "type" => "aligned" }, align: :left)
    RecordingStudioPages::CtaRenderer.call(view, { "type" => "plain" }, align: :left)

    assert_equal :left, received.first.instance_variable_get(:@align)
    assert_nil received.last.instance_variable_get(:@align)
    assert_equal "plain", received.last.instance_variable_get(:@cta)["type"]
  end

  def test_catalog_includes_ctas
    RecordingStudioPages::BuiltIns.register!

    catalog = RecordingStudioPages.catalog
    button = catalog[:ctas].find { |entry| entry[:key] == "button" }

    assert_equal "button", button[:key]
    assert_equal "Button", button[:name]
    assert_equal "string", button[:fields][:text][:type]
  end

  def test_reset_clears_ctas
    RecordingStudioPages::BuiltIns.register!
    RecordingStudioPages.reset!

    refute RecordingStudioPages.cta?(:button)
  end
end
