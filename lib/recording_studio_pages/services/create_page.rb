# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class CreatePage < Base
      def initialize(parent_recording:, title:, homepage: false, template_key: nil, actor: nil)
        @parent_recording = parent_recording
        @title = title
        @homepage = homepage
        @template_key = template_key
        @actor = actor
      end

      def perform
        with_rescue do
          recording = @parent_recording.record(RecordingStudioPages::Page, actor: actor) do |page|
            page.title = @title.to_s
            page.homepage = @homepage
            page.template_key = @template_key.to_s.presence
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
