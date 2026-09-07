# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class ReviseSection < Base
      def initialize(section_recording:, content: :keep, settings: :keep, enabled: :keep, actor: nil)
        @section_recording = section_recording
        @content = content
        @settings = settings
        @enabled = enabled
        @actor = actor
      end

      def perform
        with_rescue do
          definition = RecordingStudioPages.section(@section_recording.recordable.section_type)
          next_content = @content == :keep ? @section_recording.recordable.content : definition.read_content(@content)
          next_settings = if @settings == :keep
                            @section_recording.recordable.settings
                          else
                            definition.read_settings(@settings)
                          end
          errors = definition.validate_payload(content: next_content, settings: next_settings)
          raise InvalidSectionPayload, errors.join(", ") if errors.any?

          root_for(@section_recording).revise(@section_recording, actor: actor) do |section|
            section.content = next_content
            section.settings = next_settings
            section.enabled = @enabled unless @enabled == :keep
          end
        end
      end

      private

      def actor
        @actor || current_actor
      end
    end
  end
end
