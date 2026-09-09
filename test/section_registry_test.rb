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

  def test_starter_content_fills_required_copy
    RecordingStudioPages.register_section(
      key: :probe,
      name: "Probe",
      component: "RecordingStudioPages::Sections::HeroComponent",
      fields: { title: { type: :string, required: true }, body: :string }
    )

    assert_equal({ "title" => "Probe" }, RecordingStudioPages.section(:probe).starter_content)
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
    hero_only = RecordingStudioPages.template(:full_bleed_hero)

    assert_equal "full_bleed_hero", hero_only.key
    assert_equal 1, hero_only.sections.length
    assert_equal "hero", hero_only.sections.first.fetch("type")
    assert_equal "fullscreen_image", hero_only.sections.first.fetch("settings").to_h.stringify_keys.fetch("variant")

    home = RecordingStudioPages.template(:marketing_home)
    types = home.sections.map { |entry| entry.fetch("type") }
    hero_copy = home.sections.first.fetch("content").to_h.stringify_keys
    feature_copy = home.sections[2].fetch("content").to_h.stringify_keys
    cta_copy = home.sections[3].fetch("content").to_h.stringify_keys
    blob = [hero_copy, feature_copy, cta_copy].to_json

    assert_equal %w[hero logo_cloud feature_grid call_to_action], types
    assert_equal "The page is the front door", hero_copy.fetch("title")
    assert_equal "button", hero_copy.fetch("cta").to_h.stringify_keys.fetch("type")
    refute hero_copy.key?("primary_action")
    refute_includes blob, "recording"
    refute_includes blob, "recordable"
    refute_includes blob, "section_type"
    refute_includes blob, "gem owns"
    refute_includes blob, "RS Publishable"
  end

  def test_catalog_exposes_sections_and_templates_for_agents
    RecordingStudioPages::BuiltIns.register!

    catalog = RecordingStudioPages.catalog
    hero = catalog[:sections].find { |entry| entry[:key] == "hero" }

    assert_equal "hero", hero[:key]
    assert_equal "Hero", hero[:name]
    assert_includes hero[:variants], "split_image"
    assert_equal "string", hero[:fields][:title][:type]
    assert_equal true, hero[:fields][:title][:required]
    assert_equal "cta", hero[:fields][:cta][:type]
    assert(catalog[:templates].any? { |entry| entry[:key] == "marketing_home" })
    assert(catalog[:templates].any? { |entry| entry[:key] == "full_bleed_hero" })
    assert(catalog[:ctas].any? { |entry| entry[:key] == "button" })
  end

  def test_hero_upgrades_legacy_primary_action_on_read
    RecordingStudioPages::BuiltIns.register!
    definition = RecordingStudioPages.section(:hero)

    content = definition.read_content(
      title: "Old door",
      primary_action: { text: "Walk in", url: "/users/sign_in" }
    )

    assert_equal "button", content.dig("cta", "type")
    assert_equal "Walk in", content.dig("cta", "text")
    assert_equal "/users/sign_in", content.dig("cta", "url")
    refute content.key?("primary_action")
  end

  def test_hero_upgrades_legacy_image_url_on_read
    RecordingStudioPages::BuiltIns.register!
    definition = RecordingStudioPages.section(:hero)

    content = definition.read_content(
      title: "Old door",
      image_url: "/images/hero-tonight.jpg"
    )

    assert_equal "/images/hero-tonight.jpg", content["image"]
    refute content.key?("image_url")
    catalog = definition.fields.catalog
    assert_equal "attachment", catalog[:image][:type]
    assert_equal "image", catalog[:image][:kind]
    assert_equal "Image", catalog[:image][:label]
  end

  def test_duplicate_template_raises
    RecordingStudioPages.register_template(key: :probe, name: "Probe", sections: [], source: "pages")

    assert_raises(RecordingStudioPages::DuplicateRegistration) do
      RecordingStudioPages.register_template(key: :probe, name: "Probe", sections: [])
    end
  end
end
