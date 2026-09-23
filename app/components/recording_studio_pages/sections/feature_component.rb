# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class FeatureComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        helpers.render(FlatPack::Card::Component.new(style: :outlined)) do |card|
          image = feature_image
          card.media(aspect_ratio: "4/3", padding: :none) { image } if image
          card.body { feature_copy }
        end
      end

      private

      def feature_copy
        helpers.render(
          FlatPack::PageTitle::Component.new(
            title: @rendered.content["title"].to_s,
            subtitle: @rendered.content["body"].to_s.presence,
            variant: :h3
          )
        )
      end

      def feature_image
        url = @rendered.content["image"].to_s.strip
        return if url.blank?

        helpers.image_tag(url, alt: @rendered.content["title"].to_s, class: "h-full w-full object-cover")
      end
    end
  end
end
