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

      def logo_row
        return if items.empty?

        helpers.render(FlatPack::ChipGroup::Component.new(wrap: true, class: "mt-4")) do
          helpers.safe_join(
            items.map do |item|
              helpers.render(FlatPack::Chip::Component.new(text: item_label(item), style: :default, size: :lg))
            end
          )
        end
      end

      def item_label(item)
        item["name"].presence || item["url"].presence || "Logo"
      end
    end
  end
end
