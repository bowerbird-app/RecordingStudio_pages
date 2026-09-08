# frozen_string_literal: true

module Dummy
  module Ctas
    class SocialLoginsComponent < ViewComponent::Base
      def initialize(cta:)
        @cta = cta
      end

      # Landing CTAs use the Users OmniAuth helpers, not the sign-in partial.
      # That partial leads with an Or divider, which belongs on the auth screen.
      # Cap the stack at max-w-sm, same as the Users auth shell, so w-full
      # buttons stay equal without filling a fullscreen hero.
      def call
        return unless helpers.recording_studio_user_omniauth_configured?

        helpers.content_tag(:div, class: "mx-auto flex w-full max-w-sm flex-col gap-2") do
          helpers.safe_join(provider_buttons)
        end
      end

      private

      def provider_buttons
        helpers.recording_studio_user_omniauth_provider_names.filter_map do |provider|
          path = helpers.recording_studio_user_omniauth_authorize_path(provider)
          next if path.blank?

          logo = helpers.recording_studio_user_provider_logo(provider)
          icon = logo.to_s.start_with?("<svg") ? logo : nil
          helpers.form_with(url: path, method: :post, class: "w-full", data: { turbo: false }) do
            helpers.render(
              FlatPack::Button::Component.new(
                text: "Continue with #{helpers.recording_studio_user_provider_label(provider)}",
                icon: icon,
                type: "submit",
                style: :secondary,
                size: :md,
                class: "w-full"
              )
            )
          end
        end
      end
    end
  end
end
