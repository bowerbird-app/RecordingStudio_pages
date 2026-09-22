# frozen_string_literal: true

require "uri"

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
          upgraded = 0
          section_recordings.each do |recording|
            upgraded += 1 if upgrade_recording(recording)
          end
          upgraded
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
        return false unless child_type

        content = recording.recordable.content.to_h
        return false unless content.key?("items")

        items = FieldSchema.list_entries(content["items"]).select { |item| meaningful_item?(child_type, item) }
        RecordingStudio::Recording.transaction do
          items.each { |item| create_child!(recording, child_type, item) }
          ReviseSection.call(
            section_recording: recording,
            content: recording.recordable.content.to_h.except("items"),
            settings: recording.recordable.settings,
            actor: actor
          ).value!
        end
        true
      end

      def create_child!(parent, child_type, item)
        item = stringify(item)
        image = item["image"].to_s.strip
        child = AddSection.call(
          parent_recording: parent,
          section_type: child_type,
          content: content_for(child_type, item, image),
          actor: actor
        ).value!
        return if image.blank? || public_url?(image)

        adopted = adopt_image(child, image, parent)
        return if adopted.blank?

        ReviseSection.call(
          section_recording: child,
          content: child.reload.recordable.content.merge("image" => adopted),
          actor: actor
        ).value!
      end

      def content_for(child_type, item, image)
        stored_image = public_url?(image) ? image : nil
        if child_type == "logo"
          {
            "name" => item["name"].presence || item["url"].presence || "Logo",
            "url" => item["url"],
            "image" => stored_image
          }
        else
          {
            "title" => item["title"].presence || "Feature",
            "body" => item["body"],
            "image" => stored_image
          }
        end
      end

      def adopt_image(child, image_id, source)
        return unless child.respond_to?(:record_attachment_upload)

        attachment = RecordingStudio::Recording.find_by(id: image_id, trashed_at: nil)
        return unless attachment&.recordable_type == "RecordingStudioAttachable::Attachment"

        blob = attachment.recordable&.file&.blob
        return image_id if blob.blank?

        uploaded = child.record_attachment_upload(
          signed_blob_id: blob.signed_id,
          name: attachment.recordable.name,
          actor: actor
        )
        new_id = uploaded&.id&.to_s
        return image_id if new_id.blank?

        release_source_image(source, attachment)
        new_id
      end

      def release_source_image(source, attachment)
        return unless attachment.parent_recording_id == source.id
        return unless source.respond_to?(:remove_attachments)

        source.remove_attachments(attachment_ids: [attachment.id], actor: actor)
      rescue StandardError
        nil
      end

      def meaningful_item?(child_type, item)
        item = stringify(item)
        if child_type == "logo"
          item["name"].present? || item["url"].present? || item["image"].present?
        else
          item["title"].present? || item["body"].present? || item["image"].present?
        end
      end

      def stringify(item)
        return {} unless item.respond_to?(:to_h)

        item.to_h.stringify_keys
      end

      def public_url?(text)
        return false if text.blank?
        return true if text.start_with?("/")

        uri = URI.parse(text)
        %w[http https].include?(uri.scheme)
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
