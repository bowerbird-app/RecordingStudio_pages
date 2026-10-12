# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class MoveSection < Base
      def initialize(page_recording:, section_recording:, to_index:, actor: nil)
        @page_recording = page_recording
        @section_recording = section_recording
        @to_index = to_index
        @actor = actor
      end

      def perform
        with_rescue do
          unless @page_recording.respond_to?(:recording_studio_orderable_move!)
            raise Error, "Enable Recording Studio Orderable on the page type before reordering sections"
          end

          @page_recording.recording_studio_orderable_move!(
            @section_recording,
            to_index: @to_index,
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
