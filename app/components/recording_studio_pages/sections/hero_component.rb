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
        helpers.content_tag(:div, hero, class: "h-dvh w-full overflow-hidden bg-black")
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
          variant: variant,
          tagline: content["eyebrow"].presence,
          headline: title,
          description: description
        }
        if fullscreen_image?
          attributes[:background_image_url] = image_url
          attributes[:class] = "h-full"
        else
          attributes[:image_url] = image_url
          attributes[:image_alt] = title
        end
        attributes
      end

      def fullscreen_image?
        variant == :centered_image
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
        content["image_url"].to_s.presence
      end

      def rendered_cta
        RecordingStudioPages::CtaRenderer.call(self, content["cta"])
      end
    end
  end
end
