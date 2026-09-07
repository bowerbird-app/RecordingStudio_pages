# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class AddSection < Base
      def initialize(page_recording:, section_type:, content: {}, settings: {}, enabled: true, actor: nil)
        @page_recording = page_recording
        @section_type = section_type
        @content = content
        @settings = settings
        @enabled = enabled
        @actor = actor
      end

      def perform
        with_rescue do
          definition = RecordingStudioPages.section(@section_type)
          content = definition.read_content(@content)
          settings = definition.read_settings(@settings)
          errors = definition.validate_payload(content: content, settings: settings)
          raise InvalidSectionPayload, errors.join(", ") if errors.any?

          recording = root_for(@page_recording).record(
            RecordingStudioPages::Section,
            actor: actor,
            parent_recording: @page_recording
          ) do |section|
            section.section_type = definition.key
            section.content = content
            section.settings = settings
            section.enabled = @enabled
          end
          AppendSectionOrder.call(
            page_recording: @page_recording,
            section_recording: recording,
            actor: actor
          ).value!
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
