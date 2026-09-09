# frozen_string_literal: true

module RecordingStudioPages
  module Ctas
    class ButtonComponent < ViewComponent::Base
      def initialize(cta:)
        @cta = cta.to_h.stringify_keys
      end

      def call
        return if text.blank? || url.blank?

        render FlatPack::Button::Component.new(
          text: text,
          href: url,
          style: :primary,
          size: :md
        )
      end

      private

      def text
        @cta["text"].to_s
      end

      def url
        @cta["url"].to_s
      end
    end
  end
end
