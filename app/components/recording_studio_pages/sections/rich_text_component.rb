# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class RichTextComponent < ViewComponent::Base
      BACKGROUNDS = %w[default muted inverted].freeze
      HEADING_CLASS = [
        "text-[length:var(--text-4xl)] sm:text-[length:var(--text-5xl)]",
        "font-semibold tracking-tight leading-[1.15] fp-text-balance",
        "text-[var(--surface-content-color)]"
      ].join(" ").freeze
      BODY_CLASS = [
        "mt-8 space-y-5 text-[length:var(--text-2xl)] leading-relaxed",
        "text-[var(--surface-muted-content-color)]"
      ].join(" ").freeze
      IMAGE_CLASS = [
        "pointer-events-none absolute -bottom-8 -right-8",
        "h-48 w-48 sm:h-[75%] sm:w-[42%] sm:max-w-md",
        "object-contain object-right-bottom select-none"
      ].join(" ").freeze

      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        helpers.content_tag(:div, class: wrapper_class) do
          render FlatPack::Card::Component.new(**card_attributes) do |card|
            card.body(padding: :none) do
              helpers.content_tag(:div, class: frame_class) do
                helpers.safe_join([copy, image].compact)
              end
            end
          end
        end
      end

      private

      def copy
        helpers.content_tag(:div, class: "relative z-10 px-16 py-24") do
          helpers.content_tag(:div, class: "max-w-xl") do
            helpers.safe_join([heading, body].compact)
          end
        end
      end

      def heading
        helpers.content_tag(
          :h1,
          @rendered.content["title"].presence || "Notes",
          class: HEADING_CLASS
        )
      end

      def body
        html = helpers.sanitize(@rendered.content["body"].to_s)
        return if html.blank?

        helpers.content_tag(:div, html, class: BODY_CLASS)
      end

      def image
        url = image_url
        return if url.blank?

        helpers.image_tag(url, alt: @rendered.content["title"].to_s, class: IMAGE_CLASS)
      end

      def image_url
        @rendered.content["image"].to_s.strip.presence
      end

      def wrapper_class
        classes = [narrow? ? "mx-auto w-full max-w-prose" : "w-full"]
        classes << "overflow-hidden rounded-[var(--radius-lg)]" if image_url
        classes.join(" ")
      end

      def frame_class
        image_url ? "relative min-h-[22rem] sm:min-h-[32rem]" : "relative"
      end

      def narrow?
        @rendered.settings["variant"].to_s == "narrow"
      end

      def card_attributes
        attributes = { style: card_style, class: "w-full" }
        theme = card_theme
        attributes[:theme] = theme if theme
        attributes
      end

      def card_style
        background == "default" ? :default : :flat
      end

      def card_theme
        return unless background == "inverted"

        {
          background_muted: "var(--color-primary)",
          text: "var(--color-primary-text)",
          muted_text: "var(--color-primary-text)"
        }
      end

      def background
        value = @rendered.settings["background"].to_s
        BACKGROUNDS.include?(value) ? value : "default"
      end
    end
  end
end
