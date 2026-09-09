# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class ImageTextComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        helpers.render(FlatPack::Grid::Component.new(cols: 2, gap: :lg, align: :center)) do
          helpers.safe_join(image_right? ? [copy_column, image_column] : [image_column, copy_column])
        end
      end

      private

      def image_right?
        @rendered.settings["variant"].to_s == "image_right"
      end

      def copy_column
        helpers.safe_join(
          [
            helpers.render(FlatPack::PageTitle::Component.new(
                             title: @rendered.content["title"].presence || "Image and text",
                             subtitle: helpers.sanitize(@rendered.content["body"].to_s),
                             variant: :h2
                           )),
            action_button
          ].compact
        )
      end

      def image_column
        url = @rendered.content["image_url"].to_s.strip
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
