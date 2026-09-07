# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class HeroComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        render FlatPack::Card::Component.new(style: style) do |card|
          card.body do
            helpers.safe_join(
              [
                eyebrow,
                helpers.render(FlatPack::PageTitle::Component.new(title: title, subtitle: body, variant: :h1)),
                image_tag,
                action_button
              ].compact
            )
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

      def title
        content["title"].presence || "Untitled"
      end

      def body
        helpers.sanitize(content["body"].to_s)
      end

      def eyebrow
        return if content["eyebrow"].blank?

        helpers.content_tag(:p, content["eyebrow"], class: "text-sm font-medium")
      end

      def image_tag
        url = content["image_url"].to_s
        return if url.blank?

        helpers.image_tag(url, alt: title, class: "max-w-full")
      end

      def action_button
        action = content["primary_action"] || {}
        return if action["text"].blank? || action["url"].blank?

        helpers.render(
          FlatPack::Button::Component.new(text: action["text"], href: action["url"], style: :primary, size: :md)
        )
      end

      def style
        settings["background"].to_s == "muted" ? :outlined : :elevated
      end
    end
  end
end
