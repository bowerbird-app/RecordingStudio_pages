# frozen_string_literal: true

module RecordingStudioPages
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    include RecordingStudio::UsesDefaultLayout if defined?(RecordingStudio::UsesDefaultLayout)

    protect_from_forgery with: :exception
  end
end
