# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class ImageTextComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        render FlatPack::Card::Component.new(style: :outlined) do |card|
          card.body do
            helpers.safe_join(
              [
                helpers.render(FlatPack::PageTitle::Component.new(
                                 title: @rendered.content["title"].presence || "Image and text",
                                 subtitle: helpers.sanitize(@rendered.content["body"].to_s),
                                 variant: :h2
                               )),
                image_tag,
                action_button
              ].compact
            )
          end
        end
      end

      private

      def image_tag
        url = @rendered.content["image_url"].to_s
        return if url.blank?

        helpers.image_tag(url, alt: @rendered.content["title"].to_s, class: "max-w-full")
      end

      def action_button
        action = @rendered.content["primary_action"] || {}
        return if action["text"].blank? || action["url"].blank?

        helpers.render(
          FlatPack::Button::Component.new(text: action["text"], href: action["url"], style: :secondary, size: :md)
        )
      end
    end
  end
end
