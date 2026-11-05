# frozen_string_literal: true

module RecordingStudioPages
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    recording_studio_layout { RecordingStudioPages.configuration.layout }
    helper RecordingStudioPages::ApplicationHelper
    helper RecordingStudioPublishable::ApplicationHelper if defined?(RecordingStudioPublishable)

    protect_from_forgery with: :exception
  end
end
