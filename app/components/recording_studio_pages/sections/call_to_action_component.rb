# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class CallToActionComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        banner? ? banner : card
      end

      private

      def banner?
        @rendered.settings["variant"].to_s == "banner"
      end

      def card
        render FlatPack::Card::Component.new(style: :elevated) do |card|
          card.body { inner }
        end
      end

      def banner
        helpers.content_tag(
          :div,
          inner,
          class: "px-6 py-10 text-center bg-[var(--surface-muted-background-color)]"
        )
      end

      def inner
        action = @rendered.content["primary_action"] || {}
        helpers.safe_join(
          [
            helpers.render(FlatPack::PageTitle::Component.new(
                             title: @rendered.content["title"].presence || "Next step",
                             subtitle: @rendered.content["body"].to_s.presence,
                             variant: :h2
                           )),
            if action["text"].present? && action["url"].present?
              helpers.render(
                FlatPack::Button::Component.new(
                  text: action["text"],
                  href: action["url"],
                  style: :primary,
                  size: :md
                )
              )
            end
          ].compact
        )
      end
    end
  end
end
