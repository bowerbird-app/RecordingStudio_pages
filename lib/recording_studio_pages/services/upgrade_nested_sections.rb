# frozen_string_literal: true

module RecordingStudioPages
  module Services
    # Turns saved feature-grid and logo-cloud `items` into child sections.
    # One pass. Later saves do not write `items`.
    class UpgradeNestedSections < Base
      CHILD_TYPES = {
        "feature_grid" => "feature",
        "logo_cloud" => "logo"
      }.freeze

      def initialize(actor: nil)
        @actor = actor
      end

      def perform
        with_rescue do
          section_recordings.sum { |recording| upgrade_recording(recording) }
        end
      end

      private

      def actor
        @actor || current_actor
      end

      def section_recordings
        RecordingStudio::Recording.where(
          recordable_type: "RecordingStudioPages::Section",
          trashed_at: nil
        )
      end

      def upgrade_recording(recording)
        child_type = CHILD_TYPES[recording.recordable.section_type.to_s]
        content = recording.recordable.content.to_h
        return 0 unless child_type && content.key?("items")

        items = FieldSchema.list_entries(content["items"]).filter_map do |raw|
          item = NestedSectionItem.new(child_type, raw)
          item if item.meaningful?
        end
        RecordingStudio::Recording.transaction do
          items.each { |item| create_child!(recording, child_type, item) }
          ReviseSection.call(
            section_recording: recording,
            content: content.except("items"),
            settings: recording.recordable.settings,
            actor: actor
          ).value!
        end
        1
      end

      def create_child!(parent, child_type, item)
        child = AddSection.call(
          parent_recording: parent,
          section_type: child_type,
          content: item.content,
          actor: actor
        ).value!
        adopted = NestedSectionItem.adopt(child, item.image, parent, actor: actor)
        return if adopted.blank?

        ReviseSection.call(
          section_recording: child,
          content: child.reload.recordable.content.merge("image" => adopted),
          actor: actor
        ).value!
      end
    end
  end
end
