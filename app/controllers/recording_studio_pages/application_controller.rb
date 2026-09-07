# frozen_string_literal: true

module RecordingStudioPages
  class ApplicationController < ActionController::Base
    include RecordingStudio::UsesDefaultLayout if defined?(RecordingStudio::UsesDefaultLayout)

    protect_from_forgery with: :exception
  end
end
