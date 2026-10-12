# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class AddSection < Base
      def initialize(section_type:, page_recording: nil, parent_recording: nil, content: {}, settings: {},
                     enabled: true, actor: nil)
        @parent_recording = parent_recording || page_recording
        @section_type = section_type
        @content = content
        @settings = settings
        @enabled = enabled
        @actor = actor
      end

      def perform
        with_rescue do
          raise ArgumentError, "Pass a page or a parent section." if @parent_recording.blank?

          definition = RecordingStudioPages.section(@section_type)
          assert_parent_accepts!(definition)
          content = definition.read_content(@content)
          settings = definition.read_settings(@settings)
          errors = definition.validate_payload(content: content, settings: settings)
          raise InvalidSectionPayload, errors.join(", ") if errors.any?

          recording = root_for(@parent_recording).record(
            RecordingStudioPages::Section,
            actor: actor,
            parent_recording: @parent_recording
          ) do |section|
            section.section_type = definition.key
            section.content = content
            section.settings = settings
            section.enabled = @enabled
          end
          AppendSectionOrder.call(
            page_recording: @parent_recording,
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

      def assert_parent_accepts!(definition)
        parent_type = @parent_recording.recordable_type.to_s
        if parent_type == "RecordingStudioPages::Page"
          return if RecordingStudioPages.page_section?(definition.key)

          raise Error, "#{definition.name} belongs under its parent section."
        end

        unless parent_type == "RecordingStudioPages::Section"
          raise Error, "A section sits on a page or another section."
        end

        parent_definition = RecordingStudioPages.find_section(@parent_recording.recordable.section_type)
        return if parent_definition&.accepts_child?(definition.key)

        raise Error, "#{definition.name} does not belong on this section."
      end
    end
  end
end
