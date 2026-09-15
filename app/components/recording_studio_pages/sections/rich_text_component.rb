# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class RichTextComponent < ViewComponent::Base
      BACKGROUNDS = %w[default muted inverted].freeze

      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        helpers.content_tag(:div, class: wrapper_class) do
          render FlatPack::Card::Component.new(**card_attributes) do |card|
            card.body(padding: :lg) do
              helpers.safe_join(
                [
                  helpers.render(
                    FlatPack::PageTitle::Component.new(
                      title: @rendered.content["title"].presence || "Notes",
                      variant: :h1
                    )
                  ),
                  helpers.content_tag(
                    :div,
                    helpers.sanitize(@rendered.content["body"].to_s),
                    class: "mt-6 space-y-4 text-xl leading-relaxed text-[var(--surface-content-color)]"
                  )
                ]
              )
            end
          end
        end
      end

      private

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
