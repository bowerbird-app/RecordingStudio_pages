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
          append_order!(copy)
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

      def append_order!(recording)
        return unless recording.has_attribute?(:recording_studio_orderable_position)

        siblings = recording.parent_recording.child_recordings.where(recordable_type: "RecordingStudioPages::Section")
        max_position = siblings.maximum(:recording_studio_orderable_position)
        recording.update!(recording_studio_orderable_position: max_position ? max_position + 1 : 0)
      end
    end
  end
end
