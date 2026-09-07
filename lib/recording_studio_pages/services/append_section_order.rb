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
        return @section_recording unless @page_recording.respond_to?(:recording_studio_orderable_append!)

        @page_recording.recording_studio_orderable_append!(@section_recording, actor: actor)
        @section_recording.reload
      end
    end
  end
end
