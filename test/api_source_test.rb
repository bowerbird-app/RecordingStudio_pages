# frozen_string_literal: true

require "test_helper"

class ApiSourceTest < Minitest::Test
  def test_register_has_one_api_availability_check
    source = File.read(File.expand_path("../lib/recording_studio_pages/api.rb", __dir__))

    assert_equal 1, source.scan("defined?(::RecordingStudioApi)").size
    assert_includes source, "RecordingStudioApi.configuration.each_api { |api| register_api(api) }"
    refute_includes source, "named_api_registration_supported?"
    refute_includes source, "accepts_api_keyword?"
    refute_includes source, "yield :public"
    refute_includes source, "const_set"
    refute_includes source, "remove_const"
  end

  def test_lookup_uses_request_payload_and_context_readers
    source = File.read(File.expand_path("../lib/recording_studio_pages/api/lookup.rb", __dir__))

    assert_includes source, "RequestPayload.call(context)"
    refute_includes source, "respond_to?"
    refute_includes source, "def find!"
    refute_includes source, "accessible_recordings"
  end

  def test_section_actions_are_capability_actions
    source = File.read(File.expand_path("../lib/recording_studio_pages/api/endpoints.rb", __dir__))

    assert_includes source, "pages.catalog"
    assert_includes source, "page_sections_add"
    assert_includes source, "page_sections_duplicate"
    assert_includes source, "page_sections_toggle"
    assert_includes source, "capability: CAPABILITY"
    refute_includes source, "sections.add"
    refute_includes source, "page_sections/:id/add"
    refute_includes source, "def find!"
  end

  def test_engine_registers_the_api_after_reload
    names = RecordingStudioPages::Engine.initializers.map(&:name)

    assert_includes names, "recording_studio_pages.api"
  end
end
