# frozen_string_literal: true

module RecordingStudioPages
  class HomepagesController < ApplicationController
    layout "recording_studio_pages/public"

    skip_before_action :authenticate_user!, raise: false
    skip_recording_studio_root_resolution if respond_to?(:skip_recording_studio_root_resolution)

    def show
      recording = Composition.homepage_recording
      return head :not_found unless recording
      return head :not_found unless publicly_visible?(recording)

      @page_recording = recording
      @page = recording.recordable
      @rendered_sections = Renderer.call(recording, context: self)
    end

    private

    def publicly_visible?(recording)
      return false unless defined?(RecordingStudioPublishable)

      recording.currently_published?
    end
  end
end
