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
        else
          attributes[:image_url] = image_url
          attributes[:image_alt] = title
        end
        attributes[:style] = hero_style
        attributes.compact
      end

      def hero_style
        parts = []
        parts << "--hero-overlay-min-height: 100dvh" if fullscreen_image?
        parts.concat(text_colour_styles)
        parts.join("; ").presence
      end

      def text_colour_styles
        if fullscreen_image?
          overlay_colour_styles
        else
          surface_colour_styles
        end
      end

      def overlay_colour_styles
        styles = []
        styles << "--hero-overlay-text-color: #{title_color}" if title_color
        styles << "--hero-overlay-muted-text-color: #{body_color}" if body_color
        styles << "--hero-overlay-on-light-text-color: #{title_color}" if title_color
        styles << "--hero-overlay-on-light-muted-text-color: #{body_color}" if body_color
        styles
      end

      def surface_colour_styles
        styles = []
        styles << "--surface-content-color: #{title_color}" if title_color
        styles << "--surface-muted-content-color: #{body_color}" if body_color
        styles
      end

      def title_color
        settings["title_color"].to_s.presence
      end

      def body_color
        settings["body_color"].to_s.presence
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
        RecordingStudioPages::CtaRenderer.call(self, content["cta"], align: align)
      end
    end
  end
end
