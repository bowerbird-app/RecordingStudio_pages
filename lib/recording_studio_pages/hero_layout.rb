# frozen_string_literal: true

module RecordingStudioPages
  module HeroLayout
    LEFT_CLASS = [
      "text-left",
      "[&_.text-center]:text-left",
      "[&_.justify-center]:justify-start",
      "[&_.mx-auto]:ml-0"
    ].join(" ").freeze

    module_function

    def light_tone?(settings)
      settings.to_h.stringify_keys["tone"].to_s == "light"
    end

    def left_aligned?(settings)
      settings.to_h.stringify_keys["alignment"].to_s == "left"
    end

    def hero_class(fullscreen:, settings:)
      [
        (fullscreen && !light_tone?(settings) ? "h-full" : nil),
        (left_aligned?(settings) ? LEFT_CLASS : nil)
      ].compact.join(" ").presence
    end

    def wrap_class(settings:)
      fill = light_tone?(settings) ? "bg-cover bg-center flex items-center" : "bg-black"
      [
        "h-dvh w-full overflow-hidden",
        fill,
        (left_aligned?(settings) ? "[&_section]:justify-start" : nil)
      ].compact.join(" ")
    end

    def wrap_style(image_url)
      return if image_url.blank?

      "background-image: url('#{image_url}')"
    end
  end
end
