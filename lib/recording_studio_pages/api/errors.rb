# frozen_string_literal: true

module RecordingStudioPages
  module Api
    module Errors
      module_function

      def unwrap(result)
        return result.value if result.success?

        raise ::RecordingStudioApi::InvalidActionInputError, result.error
      end
    end
  end
end
