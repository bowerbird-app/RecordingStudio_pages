# frozen_string_literal: true

module RecordingStudioPages
  module Sections
    class RichTextComponent < ViewComponent::Base
      def initialize(rendered:)
        @rendered = rendered
      end

      def call
        helpers.content_tag(:div, class: wrapper_class) do
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

      private

      def wrapper_class
        @rendered.settings["variant"].to_s == "narrow" ? "mx-auto w-full max-w-prose" : nil
      end
    end
  end
end
