# frozen_string_literal: true

require "uri"

module RecordingStudioPages
  module Services
    class NestedSectionItem
      def initialize(child_type, item)
        @child_type = child_type.to_s
        @item = stringify(item)
      end

      def meaningful?
        keys = logo? ? %w[name url image] : %w[title body image]
        keys.any? { |key| @item[key].present? }
      end

      def content
        stored_image = public_url?(image) ? image : nil
        if logo?
          { "name" => @item["name"].presence || @item["url"].presence || "Logo", "url" => @item["url"],
            "image" => stored_image }
        else
          { "title" => @item["title"].presence || "Feature", "body" => @item["body"], "image" => stored_image }
        end
      end

      def image
        @item["image"].to_s.strip
      end

      def self.adopt(child, image_id, source, actor:)
        return if image_id.blank? || public_url?(image_id)
        return unless child.respond_to?(:record_attachment_upload)

        attachment = RecordingStudio::Recording.find_by(id: image_id, trashed_at: nil)
        return unless attachment&.recordable_type == "RecordingStudioAttachable::Attachment"

        copied = copy_blob(child, attachment, actor)
        return image_id if copied.blank?

        release(source, attachment, actor)
        copied
      end

      def self.public_url?(text)
        return false if text.blank?
        return true if text.start_with?("/")

        uri = URI.parse(text)
        %w[http https].include?(uri.scheme)
      rescue URI::InvalidURIError
        false
      end

      def self.copy_blob(child, attachment, actor)
        blob = attachment.recordable&.file&.blob
        return if blob.blank?

        uploaded = child.record_attachment_upload(
          signed_blob_id: blob.signed_id,
          name: attachment.recordable.name,
          actor: actor
        )
        uploaded&.id&.to_s
      end

      def self.release(source, attachment, actor)
        return unless attachment.parent_recording_id == source.id
        return unless source.respond_to?(:remove_attachments)

        source.remove_attachments(attachment_ids: [attachment.id], actor: actor)
      rescue StandardError
        nil
      end

      private

      def logo?
        @child_type == "logo"
      end

      def public_url?(text)
        self.class.public_url?(text)
      end

      def stringify(item)
        return {} unless item.respond_to?(:to_h)

        item.to_h.stringify_keys
      end
      private_class_method :copy_blob, :release
    end
  end
end
