# frozen_string_literal: true

module Dummy
  module Ctas
    class UrlFormComponent < ViewComponent::Base
      def initialize(cta:)
        @cta = cta.to_h.stringify_keys
      end

      def call
        helpers.form_with url: "/start", method: :get, local: true do
          helpers.tag.div(class: "flex flex-col gap-3 sm:flex-row sm:items-end") do
            helpers.safe_join(
              [
                helpers.render(
                  FlatPack::UrlInput::Component.new(
                    name: "url",
                    label: "Link",
                    value: nil,
                    placeholder: placeholder,
                    required: true
                  )
                ),
                helpers.render(
                  FlatPack::Button::Component.new(
                    text: button_text,
                    style: :primary,
                    size: :md,
                    type: "submit"
                  )
                )
              ]
            )
          end
        end
      end

      private

      def placeholder
        @cta["placeholder"].presence || "https://"
      end

      def button_text
        @cta["button_text"].presence || "Open it"
      end
    end
  end
end
