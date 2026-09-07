# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class DuplicateSection < Base
      def initialize(section_recording:, actor: nil)
        @section_recording = section_recording
        @actor = actor
      end

      def perform
        with_rescue do
          source = @section_recording.recordable
          AddSection.call(
            page_recording: @section_recording.parent_recording,
            section_type: source.section_type,
            content: source.content,
            settings: source.settings,
            enabled: source.enabled?,
            actor: actor
          ).value!
        end
      end

      private

      def actor
        @actor || current_actor
      end
    end
  end
end
