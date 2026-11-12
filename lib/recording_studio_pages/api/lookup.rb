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
        payload(context).deep_symbolize_keys
      end

      def parent_recording(context)
        parent_id = context.parent_id.presence || payload(context)["parent_id"]
        raise ::RecordingStudioApi::InvalidActionInputError, "parent_id is required" if parent_id.blank?

        parent = context.parent_recording || context.scoped_recordings.find_by(id: parent_id)
        raise ::RecordingStudioApi::NotFoundError, "Parent resource was not found in this API scope" if parent.nil?

        parent
      end

      def serialize(recording, context)
        ::RecordingStudioApi::Serializers::ResourceRecordingSerializer.call(
          recording,
          version: context.api_version,
          api: context.api_key
        )
      end
    end
  end
end
