# frozen_string_literal: true

module RecordingStudioPages
  module Services
    class Base < RecordingStudio::Services::BaseService
      private

      def current_actor
        resolver = RecordingStudio.configuration.actor if defined?(RecordingStudio)
        resolver.respond_to?(:call) ? resolver.call : nil
      end

      def root_for(recording)
        recording.root_recording || recording
      end

      def with_rescue
        success(yield)
      rescue RecordingStudioPages::Error, ArgumentError, ActiveRecord::RecordInvalid => error
        failure(error, errors: Array(error.try(:record)&.errors&.full_messages))
      end
    end
  end
end
