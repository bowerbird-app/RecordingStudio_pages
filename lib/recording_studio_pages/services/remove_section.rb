# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class RemoveSection < Base
      def initialize(section_recording:, actor: nil)
        @section_recording = section_recording
        @actor = actor
      end

      def perform
        trash_descendants(@section_recording)
        TrashRecording.call(recording: @section_recording, actor: actor)
      end

      private

      def actor
        @actor || current_actor
      end

      def trash_descendants(recording)
        Composition.child_section_recordings_for(recording).each do |child|
          trash_descendants(child)
          TrashRecording.call(recording: child, actor: actor).value!
        end
      end
    end
  end
end
