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

  def test_rich_text_article_layout_becomes_full_width
    RecordingStudioPages::BuiltIns.register!

    settings = RecordingStudioPages.section(:rich_text).read_settings(
      variant: "article",
      background: "mystery"
    )

    assert_equal "full_width", settings["variant"]
    assert_equal "default", settings["background"]
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

  def test_full_bleed_is_opt_in
    RecordingStudioPages::BuiltIns.register!
    RecordingStudioPages.register_section(
      key: :probe,
      name: "Probe",
      component: "RecordingStudioPages::Sections::HeroComponent"
    )

    refute RecordingStudioPages.section(:probe).full_bleed?
    assert_equal false, RecordingStudioPages.section(:probe).catalog[:full_bleed]
    assert RecordingStudioPages.section(:hero).full_bleed?
    assert RecordingStudioPages.section(:top_nav).full_bleed?
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

    %w[top_nav hero rich_text image_text logo_cloud feature_grid call_to_action].each do |key|
      assert RecordingStudioPages.section?(key), "expected #{key} to be registered"
    end
    assert_equal "marketing_home", RecordingStudioPages.template(:marketing_home).key
    hero_only = RecordingStudioPages.template(:full_bleed_hero)

    assert_equal "full_bleed_hero", hero_only.key
    assert_equal 1, hero_only.sections.length
    assert_equal "hero", hero_only.sections.first.fetch("type")
    assert_equal "fullscreen_image", hero_only.sections.first.fetch("settings").to_h.stringify_keys.fetch("variant")
    assert_equal "left", hero_only.sections.first.fetch("settings").to_h.stringify_keys.fetch("alignment")

    home = RecordingStudioPages.template(:marketing_home)
    types = home.sections.map { |entry| entry.fetch("type") }
    menu_copy = home.sections.first.fetch("content").to_h.stringify_keys
    hero_copy = home.sections[1].fetch("content").to_h.stringify_keys
    home_hero_settings = home.sections[1].fetch("settings").to_h.stringify_keys
    feature_copy = home.sections[3].fetch("content").to_h.stringify_keys
    cta_copy = home.sections[4].fetch("content").to_h.stringify_keys
    blob = [menu_copy, hero_copy, feature_copy, cta_copy].to_json

    assert_equal %w[top_nav hero logo_cloud feature_grid call_to_action], types
    assert_equal "House", menu_copy.fetch("name")
    assert_equal "Join", menu_copy.fetch("cta").to_h.stringify_keys.fetch("text")
    assert_equal "The page is the front door", hero_copy.fetch("title")
    assert_equal "centered", home_hero_settings.fetch("variant")
    assert_equal "left", home_hero_settings.fetch("alignment")
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
    assert_equal true, hero[:full_bleed]
    assert_includes hero[:variants], "split_image"
    menu = catalog[:sections].find { |entry| entry[:key] == "top_nav" }

    assert_equal "top_nav", menu[:key]
    assert_equal "Menu", menu[:name]
    assert_equal true, menu[:full_bleed]
    assert_equal "string", menu[:fields][:name][:type]
    assert_equal "Name", menu[:fields][:name][:label]
    assert_equal "attachment", menu[:fields][:image][:type]
    assert_equal "Mark", menu[:fields][:image][:label]
    assert_equal "list", menu[:fields][:links][:type]
    assert_equal "Links", menu[:fields][:links][:label]
    assert_equal "cta", menu[:fields][:cta][:type]
    assert_equal "Join", menu[:fields][:cta][:label]
    rich_text = catalog[:sections].find { |entry| entry[:key] == "rich_text" }

    assert_includes rich_text[:variants], "full_width"
    assert_equal "attachment", rich_text[:fields][:image][:type]
    assert_equal "image", rich_text[:fields][:image][:kind]
    assert_equal "string", rich_text[:settings][:background][:type]
    assert_equal "default", rich_text[:settings][:background][:default]
    assert_equal(
      [%w[Default default], %w[Muted muted], %w[Inverted inverted]],
      rich_text[:settings][:background][:options]
    )
    assert_equal "string", hero[:fields][:title][:type]
    assert_equal true, hero[:fields][:title][:required]
    assert_equal "cta", hero[:fields][:cta][:type]
    assert_equal "center", hero[:settings][:alignment][:default]
    assert_equal "style", hero[:settings][:alignment][:group]
    assert_equal(
      [%w[Center center], %w[Left left]],
      hero[:settings][:alignment][:options]
    )
    assert_equal "dark", hero[:settings][:background][:default]
    assert_equal "Preset", hero[:settings][:background][:label]
    assert_equal "style", hero[:settings][:background][:group]
    assert_equal "fullscreen_image", hero[:settings][:background][:show_when]["variant"]
    assert_equal true, hero[:settings][:background][:show_when]["image"]
    assert_equal(
      [["On a dark photo", "dark"], ["On a light photo", "light"]],
      hero[:settings][:background][:options]
    )
    assert_equal "color", hero[:settings][:title_color][:type]
    assert_equal "Headline", hero[:settings][:title_color][:label]
    assert_equal "style", hero[:settings][:title_color][:group]
    assert_equal "color", hero[:settings][:body_color][:type]
    assert_equal "Quieter line", hero[:settings][:body_color][:label]
    assert_equal "style", hero[:settings][:body_color][:group]
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
    settings = definition.read_settings(alignment: "right", background: "mystery")
    assert_equal "center", settings["alignment"]
    assert_equal "dark", settings["background"]
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
