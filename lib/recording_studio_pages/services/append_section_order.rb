# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class AppendSectionOrder < Base
      def initialize(page_recording:, section_recording:, actor: nil)
        @page_recording = page_recording
        @section_recording = section_recording
        @actor = actor
      end

      def perform
        with_rescue { append_to_end }
      end

      private

      def actor
        @actor || current_actor
      end

      def append_to_end
        return @section_recording unless @page_recording.respond_to?(:recording_studio_orderable_move!)

        siblings = Composition.section_recordings_for(@page_recording.reload)
        @page_recording.recording_studio_orderable_move!(
          @section_recording,
          to_index: [siblings.length - 1, 0].max,
          actor: actor
        )
        @section_recording.reload
      end
    end
  end
end
