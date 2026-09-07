# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class RichTextComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        render FlatPack::Card::Component.new(style: :default) do |card|
          card.body do
            helpers.safe_join(
              [
                helpers.render(
                  FlatPack::PageTitle::Component.new(
                    title: @rendered.content["title"].presence || "Notes",
                    variant: :h2
                  )
                ),
                helpers.content_tag(
                  :div,
                  helpers.sanitize(@rendered.content["body"].to_s),
                  class: "mt-4 space-y-3 text-base leading-relaxed text-[var(--surface-content-color)]"
                )
              ]
            )
          end
        end
      end
    end
  end
end
