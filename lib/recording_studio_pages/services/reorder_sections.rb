# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class ReorderSections < Base
      def initialize(page_recording:, ordered_recording_ids:, actor: nil)
        @page_recording = page_recording
        @ordered_recording_ids = ordered_recording_ids
        @actor = actor
      end

      def perform
        with_rescue do
          unless @page_recording.respond_to?(:recording_studio_orderable_reorder!)
            raise Error, "Enable Recording Studio Orderable on the page type before reordering sections"
          end

          @page_recording.recording_studio_orderable_reorder!(
            ordered_recording_ids: @ordered_recording_ids,
            actor: actor
          )
        end
      end

      private

      def actor
        @actor || current_actor
      end
    end
  end
end
