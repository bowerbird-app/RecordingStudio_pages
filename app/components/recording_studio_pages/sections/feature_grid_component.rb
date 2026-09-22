# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class FeatureGridComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        helpers.safe_join(
          [
            helpers.render(FlatPack::PageTitle::Component.new(
                             title: @rendered.content["title"].presence || "Features",
                             subtitle: @rendered.content["body"].to_s.presence,
                             variant: :h2
                           )),
            helpers.render(FlatPack::Grid::Component.new(cols: grid_columns, gap: :md)) do
              helpers.safe_join(items.map { |item| feature_card(item) })
            end
          ]
        )
      end

      private

      def items
        children = RecordingStudioPages::Composition.renderable_child_section_recordings_for(@rendered.recording)
        children.filter_map do |recording|
          RecordingStudioPages::Renderer.section(recording, context: helpers)&.content
        end
      end

      def grid_columns
        case @rendered.settings["variant"].to_s
        when "alternating_rows" then 1
        when "icon_grid" then 4
        else
          3
        end
      end

      def feature_card(item)
        helpers.render(FlatPack::Card::Component.new(style: card_style)) do |card|
          card.body do
            helpers.safe_join([feature_image(item), feature_copy(item)].compact)
          end
        end
      end

      def feature_copy(item)
        helpers.render(
          FlatPack::PageTitle::Component.new(
            title: item["title"].to_s,
            subtitle: item["body"].to_s.presence,
            variant: :h3
          )
        )
      end

      def feature_image(item)
        url = item["image"].to_s.strip
        return if url.blank?

        helpers.image_tag(url, alt: item["title"].to_s, class: "mb-4 max-h-40 max-w-full")
      end

      def card_style
        @rendered.settings["variant"].to_s == "icon_grid" ? :default : :outlined
      end
    end
  end
end
