# frozen_string_literal: true

require "uri"

module RecordingStudioPages
  class AttachmentUrl
    ATTACHMENT_TYPE = "RecordingStudioAttachable::Attachment"

    def self.call(value, recording:, context: nil)
      new(value, recording: recording, context: context).call
    end

    def initialize(value, recording:, context: nil)
      @value = value
      @recording = recording
      @context = context
    end

    def call
      text = @value.to_s.strip
      return if text.blank?
      return text if public_url?(text)

      blob_url_for(find_attachment_recording(text))
    end

    private

    def public_url?(text)
      return true if text.start_with?("/")

      uri = URI.parse(text)
      %w[http https].include?(uri.scheme)
    rescue URI::InvalidURIError
      false
    end

    def find_attachment_recording(id)
      return unless defined?(RecordingStudio::Recording)

      attachment = RecordingStudio::Recording.find_by(id: id, trashed_at: nil)
      return unless attachment
      return unless attachment.recordable_type == ATTACHMENT_TYPE
      return unless same_tree?(attachment)

      attachment
    end

    def same_tree?(attachment)
      return true if @recording.blank?
      return true if attachment.root_recording_id.blank? || @recording.root_recording_id.blank?

      attachment.root_recording_id == @recording.root_recording_id
    end

    def blob_url_for(attachment_recording)
      return if attachment_recording.blank?

      blob = attachment_recording.recordable&.file&.blob
      return if blob.blank?

      blob_path(blob)
    rescue StandardError
      nil
    end

    def blob_path(blob)
      helpers = @context
      if helpers.respond_to?(:main_app) && helpers.main_app.respond_to?(:rails_blob_path)
        return helpers.main_app.rails_blob_path(blob, only_path: true)
      end
      if helpers.respond_to?(:rails_blob_path)
        return helpers.rails_blob_path(blob, only_path: true)
      end

      Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
    end
  end
end
