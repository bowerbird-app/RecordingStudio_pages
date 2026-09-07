# frozen_string_literal: true

require "test_helper"

class SectionRegistryTest < Minitest::Test
  def setup
    RecordingStudioPages.reset!
  end

  def teardown
    RecordingStudioPages.reset!
    RecordingStudioPages::BuiltIns.register!
  end

  def test_register_and_lookup
    RecordingStudioPages.register_section(
      key: :probe,
      name: "Probe",
      component: "RecordingStudioPages::Sections::HeroComponent",
      fields: { title: :string }
    )

    definition = RecordingStudioPages.section(:probe)

    assert RecordingStudioPages.section?(:probe)
    assert_equal "probe", definition.key
    assert_equal "Probe", definition.name
    assert_includes RecordingStudioPages.sections.map(&:key), "probe"
  end

  def test_duplicate_registration_raises
    attributes = {
      key: :probe,
      name: "Probe",
      component: "RecordingStudioPages::Sections::HeroComponent",
      source: "pages"
    }
    RecordingStudioPages.register_section(**attributes)

    error = assert_raises(RecordingStudioPages::DuplicateRegistration) do
      RecordingStudioPages.register_section(**attributes)
    end
    assert_includes error.message, "probe"
    assert_includes error.message, "pages"
  end

  def test_unknown_section_fetch_raises_and_find_is_nil
    assert_nil RecordingStudioPages.find_section(:missing)
    refute RecordingStudioPages.section?(:missing)
    assert_raises(RecordingStudioPages::UnknownSectionType) { RecordingStudioPages.section(:missing) }
  end

  def test_variants_normalize_unknown_values
    RecordingStudioPages.register_section(
      key: :probe,
      name: "Probe",
      component: "RecordingStudioPages::Sections::HeroComponent",
      settings: { variant: :string },
      variants: %w[centered split]
    )

    settings = RecordingStudioPages.section(:probe).read_settings(variant: "mystery")

    assert_equal "centered", settings["variant"]
  end

  def test_payload_validation_rejects_bad_urls
    RecordingStudioPages.register_section(
      key: :probe,
      name: "Probe",
      component: "RecordingStudioPages::Sections::HeroComponent",
      fields: { image_url: :url }
    )

    errors = RecordingStudioPages.section(:probe).validate_payload(
      content: { "image_url" => "javascript:alert(1)" },
      settings: {}
    )

    refute_empty errors
  end

  def test_built_ins_and_marketing_home_template_are_registered
    RecordingStudioPages::BuiltIns.register!

    %w[hero rich_text image_text logo_cloud feature_grid call_to_action].each do |key|
      assert RecordingStudioPages.section?(key), "expected #{key} to be registered"
    end
    assert_equal "marketing_home", RecordingStudioPages.template(:marketing_home).key
  end

  def test_duplicate_template_raises
    RecordingStudioPages.register_template(key: :probe, name: "Probe", sections: [], source: "pages")

    assert_raises(RecordingStudioPages::DuplicateRegistration) do
      RecordingStudioPages.register_template(key: :probe, name: "Probe", sections: [])
    end
  end
end
