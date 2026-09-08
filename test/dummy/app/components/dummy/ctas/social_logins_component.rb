# frozen_string_literal: true

module Dummy
  module Ctas
    class SocialLoginsComponent < ViewComponent::Base
      def initialize(cta:)
        @cta = cta
      end

      def call
        helpers.render partial: "recording_studio_user/omniauth/continue_with_providers"
      end
    end
  end
end
