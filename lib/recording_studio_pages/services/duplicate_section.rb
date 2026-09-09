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
          copy_section_images(source: @section_recording, copy: copy)
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

      def copy_section_images(source:, copy:)
        return unless copy.respond_to?(:record_attachment_upload)
        return unless defined?(RecordingStudioAttachable::Attachment)

        mapping = {}
        attachment_children(source).each do |child|
          blob = child.recordable&.file&.blob
          next unless blob

          new_child = copy.record_attachment_upload(
            signed_blob_id: blob.signed_id,
            name: child.recordable.name,
            actor: actor
          )
          mapping[child.id.to_s] = new_child.id.to_s if new_child.respond_to?(:id)
        end
        return if mapping.empty?

        definition = RecordingStudioPages.find_section(copy.recordable.section_type)
        return unless definition

        remapped = definition.fields.remap_attachments(copy.recordable.content, mapping)
        return if remapped == copy.recordable.content

        ReviseSection.call(section_recording: copy, content: remapped, actor: actor).value!
      end

      def attachment_children(recording)
        recording.child_recordings.select do |child|
          child.recordable_type == "RecordingStudioAttachable::Attachment"
        end
      end
    end
  end
end
