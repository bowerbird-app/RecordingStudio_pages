# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class RemoveSection < Base
      def initialize(section_recording:, actor: nil)
        @section_recording = section_recording
        @actor = actor
      end

      def perform
        TrashRecording.call(recording: @section_recording, actor: actor)
      end

      private

      def actor
        @actor || current_actor
      end
    end
  end
end
