# frozen_string_literal: true

module RecordingStudioPages
  module MenuOverlay
    module_function

    def overlay?(rendered, following)
      rendered.definition.key.to_s == "top_nav" && over_fullscreen_hero?(following)
    end

    def over_fullscreen_hero?(following)
      return false if following.blank?

      following.definition.key.to_s == "hero" &&
        following.settings.to_h.stringify_keys["variant"].to_s == "fullscreen_image"
    end
  end
end
