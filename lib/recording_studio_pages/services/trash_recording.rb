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
          if trashable?
            @recording.recording_studio_trashable_trash!(actor: actor)
          else
            fallback_trash!
          end
          @recording
        end
      end

      private

      def actor
        @actor || current_actor
      end

      def trashable?
        @recording.respond_to?(:recording_studio_trashable_trash!) &&
          defined?(RecordingStudio) &&
          RecordingStudio.capability_enabled?(:trashable, for: @recording.recordable_type)
      end

      def fallback_trash!
        unless @recording.has_attribute?(:trashed_at)
          raise Error, "Install Recording Studio Trashable before removing this."
        end

        @recording.log_event!(action: "trashed", actor: actor) if @recording.respond_to?(:log_event!)
        attributes = { trashed_at: Time.current }
        attributes[:trash_root] = true if @recording.has_attribute?(:trash_root)
        @recording.update!(attributes)
      end
    end
  end
end
