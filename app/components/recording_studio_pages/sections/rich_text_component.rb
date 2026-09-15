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

      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        helpers.content_tag(:div, class: wrapper_class) do
          render FlatPack::Card::Component.new(**card_attributes) do |card|
            card.body(padding: :none) do
              helpers.content_tag(:div, class: "px-16 py-24") do
                helpers.content_tag(:div, class: "max-w-xl") do
                  helpers.safe_join([heading, body].compact)
                end
              end
            end
          end
        end
      end

      private

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

      def wrapper_class
        narrow? ? "mx-auto w-full max-w-prose" : "w-full"
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
