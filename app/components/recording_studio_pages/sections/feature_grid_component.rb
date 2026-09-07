# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class FeatureGridComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        render FlatPack::Card::Component.new(style: :default) do |card|
          card.body do
            helpers.safe_join(
              [
                helpers.render(FlatPack::PageTitle::Component.new(
                                 title: @rendered.content["title"].presence || "Features",
                                 subtitle: @rendered.content["body"].to_s.presence,
                                 variant: :h2
                               )),
                helpers.content_tag(:div, class: "grid gap-4 md:grid-cols-3") do
                  helpers.safe_join(items.map { |item| feature_card(item) })
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

      def feature_card(item)
        helpers.render(FlatPack::Card::Component.new(style: :outlined)) do |card|
          card.body do
            helpers.render(
              FlatPack::PageTitle::Component.new(
                title: item["title"].to_s,
                subtitle: item["body"].to_s,
                variant: :h3
              )
            )
          end
        end
      end
    end
  end
end
