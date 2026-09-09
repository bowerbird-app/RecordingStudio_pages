# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class LogoCloudComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        helpers.safe_join(
          [
            helpers.render(FlatPack::PageTitle::Component.new(
                             title: @rendered.content["title"].presence || "Logos",
                             variant: :h2
                           )),
            logo_row
          ].compact
        )
      end

      private

      def items
        Array(@rendered.content["items"])
      end

      def compact?
        @rendered.settings["variant"].to_s == "compact"
      end

      def logo_row
        return if items.empty?

        helpers.render(FlatPack::ChipGroup::Component.new(wrap: true, class: "mt-4")) do
          helpers.safe_join(items.map { |item| logo_item(item) })
        end
      end

      def logo_item(item)
        if item["image"].present?
          helpers.image_tag(
            item["image"],
            alt: item_label(item),
            class: compact? ? "h-8" : "h-10"
          )
        else
          helpers.render(
            FlatPack::Chip::Component.new(
              text: item_label(item),
              style: :default,
              size: compact? ? :sm : :lg
            )
          )
        end
      end

      def item_label(item)
        item["name"].presence || item["url"].presence || "Logo"
      end
    end
  end
end
