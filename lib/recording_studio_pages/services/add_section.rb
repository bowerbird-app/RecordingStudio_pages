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

          recording = @page_recording.record(RecordingStudioPages::Section, actor: actor) do |section|
            section.section_type = definition.key
            section.content = content
            section.settings = settings
            section.enabled = @enabled
          end
          append_order!(recording)
          recording
        end
      end

      private

      def actor
        @actor || current_actor
      end

      def append_order!(recording)
        return unless @page_recording.respond_to?(:recording_studio_orderable_children)

        ids = @page_recording.recording_studio_orderable_children.map { |child| child.id.to_s }
        ids << recording.id.to_s unless ids.include?(recording.id.to_s)
        @page_recording.recording_studio_orderable_reorder!(ordered_recording_ids: ids, actor: actor)
      end
    end
  end
end
