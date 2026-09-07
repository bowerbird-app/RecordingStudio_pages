# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class RemovePage < Base
      def initialize(page_recording:, actor: nil)
        @page_recording = page_recording
        @actor = actor
      end

      def perform
        TrashRecording.call(recording: @page_recording, actor: actor)
      end

      private

      def actor
        @actor || current_actor
      end
    end
  end
end
