# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class TrashRecording < Base
      def initialize(recording:, actor: nil)
        @recording = recording
        @actor = actor
      end

      def perform
        with_rescue do
          if @recording.respond_to?(:trash!)
            @recording.trash!(actor: actor)
          else
            raise Error, "Install Recording Studio Trashable before removing this." unless @recording.has_attribute?(:trashed_at)

            @recording.log_event!(action: "trashed", actor: actor) if @recording.respond_to?(:log_event!)
            @recording.update!(trashed_at: Time.current)
          end
          @recording
        end
      end

      private

      def actor
        @actor || current_actor
      end
    end
  end
end
