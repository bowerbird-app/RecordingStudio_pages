# frozen_string_literal: true

module RecordingStudioPages
  module Api
    module Documentation
      module_function

      def json_body(**properties)
        {
          content: {
            "application/json" => {
              schema: { properties: properties }
            }
          }
        }
      end
    end
  end
end
