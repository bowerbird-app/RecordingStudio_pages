# frozen_string_literal: true

module RecordingStudioPages
  module Api
    module Lookup
      PAGE_TYPE = "RecordingStudioPages::Page"
      SECTION_TYPE = "RecordingStudioPages::Section"

      module_function

      def payload(context)
        ::RecordingStudioApi::RequestPayload.call(context)
      end

      def symbolized_payload(context)
        raw = payload(context)
        raw.respond_to?(:deep_symbolize_keys) ? raw.deep_symbolize_keys : raw.to_h.transform_keys(&:to_sym)
      end

      def recordings(context)
        if context.respond_to?(:scoped_recordings) && context.scoped_recordings
          context.scoped_recordings
        else
          context.access_grant.accessible_recordings
        end
      end

      def find!(context, id, types:)
        recording = recordings(context).find_by(id: id)
        if recording.nil? || Array(types).exclude?(recording.recordable_type)
          raise ::RecordingStudioApi::NotFoundError, "Resource was not found in this API scope"
        end

        recording
      end

      def parent_recording(context)
        parent_id = context.parent_id.presence || payload(context)[:parent_id] || payload(context)["parent_id"]
        raise ::RecordingStudioApi::InvalidActionInputError, "parent_id is required" if parent_id.blank?

        parent = recordings(context).find_by(id: parent_id)
        raise ::RecordingStudioApi::NotFoundError, "Parent resource was not found in this API scope" if parent.nil?

        parent
      end

      def actor(context)
        if context.respond_to?(:actor)
          context.actor
        else
          context.access_grant.actor
        end
      end

      def serialize(recording, context)
        api = context.respond_to?(:api_key) ? context.api_key : :public
        version = context.respond_to?(:api_version) ? context.api_version : nil
        ::RecordingStudioApi::Serializers::ResourceRecordingSerializer.call(
          recording,
          version: version,
          api: api
        )
      end
    end
  end
end
