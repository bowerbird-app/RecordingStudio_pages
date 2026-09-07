# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class ApplyTemplate < Base
      def initialize(page_recording:, template_key:, actor: nil)
        @page_recording = page_recording
        @template_key = template_key
        @actor = actor
      end

      def perform
        with_rescue do
          template = RecordingStudioPages.template(@template_key)
          recordings = template.sections.map do |entry|
            AddSection.call(
              page_recording: @page_recording.reload,
              section_type: entry.fetch("type"),
              content: entry.fetch("content"),
              settings: entry.fetch("settings"),
              enabled: entry.fetch("enabled"),
              actor: actor
            ).value!
          end
          RevisePage.call(page_recording: @page_recording, template_key: template.key, actor: actor).value!
          recordings
        end
      end

      private

      def actor
        @actor || current_actor
      end
    end
  end
end
