# frozen_string_literal: true

require "test_helper"

class TopNavOverlayTest < Minitest::Test
  FakeSection = Struct.new(:definition, :settings)

  def setup
    RecordingStudioPages.reset!
    RecordingStudioPages::BuiltIns.register!
  end

  def teardown
    RecordingStudioPages.reset!
    RecordingStudioPages::BuiltIns.register!
  end

  def test_menu_overlays_a_following_fullscreen_hero
    menu = fake_section("top_nav")
    hero = fake_section("hero", "fullscreen_image")

    assert RecordingStudioPages::MenuOverlay.overlay?(menu, hero)
  end

  def test_menu_does_not_overlay_a_centered_hero
    menu = fake_section("top_nav")
    hero = fake_section("hero", "centered")

    refute RecordingStudioPages::MenuOverlay.overlay?(menu, hero)
  end

  def test_menu_does_not_overlay_rich_text
    menu = fake_section("top_nav")
    copy = fake_section("rich_text")

    refute RecordingStudioPages::MenuOverlay.overlay?(menu, copy)
    refute RecordingStudioPages::MenuOverlay.overlay?(menu, nil)
    assert_includes RecordingStudioPages::MenuOverlay.token_style, "--button-ghost-text-color: white"
  end

  private

  def fake_section(key, variant = nil)
    FakeSection.new(
      RecordingStudioPages.section(key),
      variant ? { "variant" => variant } : {}
    )
  end
end
