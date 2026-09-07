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
        render FlatPack::Hero::Component.new(**hero_attributes) do |hero|
          if action_present?
            hero.slot do
              render FlatPack::Button::Component.new(
                text: action["text"],
                href: action["url"],
                style: :primary,
                size: :md
              )
            end
          end
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
          tagline: content["eyebrow"].presence,
          headline: title,
          description: description
        }
        if variant == :centered_image
          attributes[:background_image_url] = image_url
        else
          attributes[:image_url] = image_url
          attributes[:image_alt] = title
        end
        attributes
      end

      def variant
        mapped = FLATPACK_VARIANTS.fetch(settings["variant"].to_s, :centered)
        return :centered if mapped == :split_image && image_url.blank?

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

      def action
        content["primary_action"] || {}
      end

      def action_present?
        action["text"].present? && action["url"].present?
      end
    end
  end
end
