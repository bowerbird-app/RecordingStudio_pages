# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class RevisePage < Base
      def initialize(page_recording:, title: nil, homepage: nil, actor: nil)
        @page_recording = page_recording
        @title = title
        @homepage = homepage
        @actor = actor
      end

      def perform
        with_rescue do
          recording = root_for(@page_recording).revise(@page_recording, actor: actor) do |page|
            page.title = @title unless @title.nil?
            page.homepage = @homepage unless @homepage.nil?
          end
          ClearOtherHomepages.call(page_recording: recording, actor: actor).value! if recording.recordable.homepage?
          recording
        end
      end

      private

      def actor
        @actor || current_actor
      end
    end
  end
end
