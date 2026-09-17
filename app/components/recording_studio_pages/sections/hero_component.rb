# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class HeroComponent < ViewComponent::Base
      FLATPACK_VARIANTS = {
        "centered" => :centered,
        "split_image" => :split_image,
        "fullscreen_image" => :centered_image
      }.freeze

      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        cta = rendered_cta
        hero = render FlatPack::Hero::Component.new(**hero_attributes) do |component|
          component.slot { cta } if cta
        end
        return hero unless fullscreen_image?

        # Flatpack :centered_image is min-h-[560px] and TailwindMerge applies
        # that after our classes, so a min-height on the section cannot win.
        # A 100dvh wrap plus h-full on the section fills the public viewport.
        helpers.content_tag(:div, hero, class: wrap_class, style: wrap_style)
      end

      private

      def content
        @rendered.content
      end

      def settings
        @rendered.settings
      end

      def hero_attributes
        attributes = {
          variant: fullscreen_image? && light? ? :centered : variant,
          tagline: content["eyebrow"].presence,
          headline: title,
          description: description,
          class: RecordingStudioPages::HeroLayout.hero_class(
            fullscreen: fullscreen_image?,
            settings: settings
          )
        }
        if fullscreen_image? && !light?
          attributes[:background_image_url] = image_url
        elsif !fullscreen_image?
          attributes[:image_url] = image_url
          attributes[:image_alt] = title
        end
        attributes
      end

      def wrap_class
        RecordingStudioPages::HeroLayout.wrap_class(settings: settings)
      end

      def wrap_style
        return unless fullscreen_image? && light?

        RecordingStudioPages::HeroLayout.wrap_style(image_url)
      end

      def fullscreen_image?
        variant == :centered_image
      end

      def light?
        RecordingStudioPages::HeroLayout.light_tone?(settings)
      end

      def variant
        mapped = FLATPACK_VARIANTS.fetch(settings["variant"].to_s, :centered)
        return :centered if image_url.blank? && %i[split_image centered_image].include?(mapped)

        mapped
      end

      def title
        content["title"].presence || "Untitled"
      end

      def description
        helpers.strip_tags(content["body"].to_s).presence
      end

      def image_url
        content["image"].to_s.presence
      end

      def rendered_cta
        RecordingStudioPages::CtaRenderer.call(self, content["cta"])
      end
    end
  end
end
