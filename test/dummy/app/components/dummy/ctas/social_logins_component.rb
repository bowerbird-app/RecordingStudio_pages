# frozen_string_literal: true

module Dummy
  module Ctas
    class SocialLoginsComponent < ViewComponent::Base
      def initialize(cta:)
        @cta = cta
      end

      def call
        render FlatPack::ButtonGroup::Component.new do |group|
          group.button(
            FlatPack::Button::Component.new(
              text: "Continue with Google",
              href: "/users/sign_in",
              style: :secondary,
              size: :md
            )
          )
          group.button(
            FlatPack::Button::Component.new(
              text: "Continue with Apple",
              href: "/users/sign_in",
              style: :secondary,
              size: :md
            )
          )
        end
      end
    end
  end
end
