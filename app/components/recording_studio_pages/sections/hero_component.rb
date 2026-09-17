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
        render FlatPack::Hero::Component.new(**hero_attributes) do |component|
          component.slot { cta } if cta
        end
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
          align: align,
          tagline: content["eyebrow"].presence,
          headline: title,
          description: description
        }
        if fullscreen_image?
          attributes[:background_image_url] = image_url
          attributes[:on] = overlay_on
          attributes[:style] = "--hero-overlay-min-height: 100dvh"
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

      def align
        settings["alignment"].to_s == "left" ? :left : :center
      end

      def overlay_on
        settings["background"].to_s == "light" ? :light : :dark
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
