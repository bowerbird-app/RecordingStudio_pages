# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class ClearOtherHomepages < Base
      def initialize(page_recording:, actor: nil)
        @page_recording = page_recording
        @actor = actor
      end

      def perform
        with_rescue do
          homepage_recordings.each do |recording|
            next if recording.id == @page_recording.id

            root_for(recording).revise(recording, actor: actor) do |page|
              page.homepage = false
            end
          end
          @page_recording
        end
      end

      private

      def actor
        @actor || current_actor
      end

      def homepage_recordings
        root = root_for(@page_recording)
        root.recordings_of(RecordingStudioPages::Page).includes(:recordable).select do |recording|
          recording.recordable.respond_to?(:homepage?) && recording.recordable.homepage?
        end
      end
    end
  end
end
