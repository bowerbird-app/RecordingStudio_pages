# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class RemoveSection < Base
      def initialize(section_recording:, actor: nil)
        @section_recording = section_recording
        @actor = actor
      end

      def perform
        with_rescue do
          if @section_recording.respond_to?(:trash!)
            @section_recording.trash!(actor: actor)
          else
            @section_recording.update!(trashed_at: Time.current)
            if @section_recording.respond_to?(:log_event!)
              @section_recording.log_event!(action: "trashed", actor: actor)
            end
          end
          @section_recording
        end
      end

      private

      def actor
        @actor || current_actor
      end
    end
  end
end
