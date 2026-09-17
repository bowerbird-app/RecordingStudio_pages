# frozen_string_literal: true

module RecordingStudioPages
  module MenuOverlay
    # Ghost buttons over a photo need a top scrim (taste). These tokens invert
    # Menu chrome onto that photo without a second TopNav variant in Flatpack.
    TOKENS = {
      "--top-nav-background-color" => "transparent",
      "--top-nav-item-icon-color" => "white",
      "--top-nav-item-hover-text-color" => "white",
      "--top-nav-item-hover-background-color" => "rgb(255 255 255 / 0.12)",
      "--button-ghost-text-color" => "white",
      "--button-ghost-hover-text-color" => "white",
      "--button-ghost-hover-background-color" => "rgb(255 255 255 / 0.12)",
      "--button-ghost-border-color" => "transparent",
      "--button-primary-background-color" => "white",
      "--button-primary-text-color" => "oklch(0.25 0.01 80)",
      "--button-primary-hover-background-color" => "oklch(0.96 0.01 80)",
      "--button-primary-border-color" => "transparent",
      "--surface-background-color" => "oklch(0.22 0.02 80)",
      "--surface-content-color" => "white",
      "--surface-border-color" => "rgb(255 255 255 / 0.14)"
    }.freeze

    LIGHT_TOKENS = {
      "--top-nav-background-color" => "transparent"
    }.freeze

    DARK_SCRIM = "bg-gradient-to-b from-black/50 to-transparent pb-10"
    LIGHT_SCRIM = "bg-gradient-to-b from-white/70 to-transparent pb-10"

    module_function

    def overlay?(rendered, following)
      rendered.definition.key.to_s == "top_nav" && over_fullscreen_hero?(following)
    end

    def over_fullscreen_hero?(following)
      return false if following.blank?

      following.definition.key.to_s == "hero" &&
        following.settings.to_h.stringify_keys["variant"].to_s == "fullscreen_image"
    end

    def token_style(following = nil)
      tokens_for(following).map { |name, value| "#{name}: #{value}" }.join("; ")
    end

    def scrim_class(following = nil)
      HeroLayout.light_tone?(following&.settings) ? LIGHT_SCRIM : DARK_SCRIM
    end

    def tokens_for(following)
      HeroLayout.light_tone?(following&.settings) ? LIGHT_TOKENS : TOKENS
    end
  end
end
