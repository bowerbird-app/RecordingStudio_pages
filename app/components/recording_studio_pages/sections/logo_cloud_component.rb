# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class LogoCloudComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        render FlatPack::Card::Component.new(style: :outlined) do |card|
          card.body do
            helpers.safe_join(
              [
                helpers.render(FlatPack::PageTitle::Component.new(
                                 title: @rendered.content["title"].presence || "Logos",
                                 variant: :h2
                               )),
                helpers.content_tag(:ul, class: "flex flex-wrap gap-4") do
                  helpers.safe_join(items.map { |item| helpers.content_tag(:li, item_label(item)) })
                end
              ]
            )
          end
        end
      end

      private

      def items
        Array(@rendered.content["items"])
      end

      def item_label(item)
        item["name"].presence || item["url"].presence || "Logo"
      end
    end
  end
end
