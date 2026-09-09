# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class ToggleSection < Base
      def initialize(section_recording:, enabled:, actor: nil)
        @section_recording = section_recording
        @enabled = enabled
        @actor = actor
      end

      def perform
        ReviseSection.call(
          section_recording: @section_recording,
          enabled: @enabled,
          actor: actor
        )
      end

      private

      def actor
        @actor || current_actor
      end
    end
  end
end
