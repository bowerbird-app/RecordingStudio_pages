# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class LogoComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        if image_url.present?
          helpers.image_tag(image_url, alt: label, class: "h-10")
        else
          helpers.render(FlatPack::Chip::Component.new(text: label, style: :default, size: :lg))
        end
      end

      private

      def image_url
        @rendered.content["image"].to_s.strip
      end

      def label
        @rendered.content["name"].presence || @rendered.content["url"].presence || "Logo"
      end
    end
  end
end
