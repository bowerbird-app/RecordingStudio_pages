# frozen_string_literal: true

require "test_helper"

class HeroLayoutTest < Minitest::Test
  def test_left_fullscreen_wrap_and_hero_classes
    settings = { "alignment" => "left", "tone" => "dark" }

    assert RecordingStudioPages::HeroLayout.left_aligned?(settings)
    refute RecordingStudioPages::HeroLayout.light_tone?(settings)
    assert_includes RecordingStudioPages::HeroLayout.hero_class(fullscreen: true, settings: settings), "h-full"
    assert_includes RecordingStudioPages::HeroLayout.hero_class(fullscreen: true, settings: settings), "text-left"
    assert_includes RecordingStudioPages::HeroLayout.wrap_class(settings: settings), "bg-black"
    assert_includes RecordingStudioPages::HeroLayout.wrap_class(settings: settings), "[&_section]:justify-start"
  end

  def test_light_center_wrap_uses_the_photo_not_a_black_fill
    settings = { "alignment" => "center", "tone" => "light" }

    refute RecordingStudioPages::HeroLayout.left_aligned?(settings)
    assert RecordingStudioPages::HeroLayout.light_tone?(settings)
    assert_nil RecordingStudioPages::HeroLayout.hero_class(fullscreen: true, settings: settings)
    wrap = RecordingStudioPages::HeroLayout.wrap_class(settings: settings)
    assert_includes wrap, "bg-cover bg-center"
    assert_includes wrap, "flex items-center"
    refute_includes wrap, "bg-black"
    refute_includes wrap, "justify-start"
    assert_equal "background-image: url('/images/hero-home-center-pastel.png')",
                 RecordingStudioPages::HeroLayout.wrap_style("/images/hero-home-center-pastel.png")
  end
end
