# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class DuplicateSection < Base
      def initialize(section_recording:, actor: nil)
        @section_recording = section_recording
        @actor = actor
      end

      def perform
        with_rescue do
          unless duplicatable_enabled?
            raise Error, "Enable Recording Studio Duplicatable on the section type before copying sections"
          end

          copy = duplicate_in_place
          AppendSectionOrder.call(
            page_recording: copy.parent_recording,
            section_recording: copy,
            actor: actor
          ).value!
          copy
        end
      end

      private

      def actor
        @actor || current_actor
      end

      def duplicatable_enabled?
        defined?(RecordingStudioDuplicatable) && @section_recording.respond_to?(:duplicate_in_place!)
      end

      def duplicate_in_place
        @section_recording.duplicate_in_place!(
          actor: actor,
          prefix: nil,
          suffix: nil,
          include_children: nil
        )
      rescue *duplication_failure_classes => e
        raise Error, copy_error_message(e)
      end

      def duplication_failure_classes
        classes = []
        classes << RecordingStudio::CapabilityDisabled if defined?(RecordingStudio::CapabilityDisabled)
        classes << RecordingStudioDuplicatable::AccessDenied if defined?(RecordingStudioDuplicatable::AccessDenied)
        classes
      end

      def copy_error_message(error)
        if defined?(RecordingStudioDuplicatable::AccessDenied) && error.is_a?(RecordingStudioDuplicatable::AccessDenied)
          "You don't have access to copy this section."
        else
          "Enable Recording Studio Duplicatable on the section type before copying sections"
        end
      end
    end
  end
end
