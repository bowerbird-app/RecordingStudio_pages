# frozen_string_literal: true

module RecordingStudioPages
  class HomepagesController < ApplicationController
    skip_before_action :authenticate_user!, raise: false

    def show
      recording = Composition.homepage_recording
      return head :not_found unless recording
      return head :not_found unless publicly_visible?(recording)

      @page_recording = recording
      @page = recording.recordable
      @rendered_sections = Renderer.call(recording, context: self)
      render :show, layout: public_layout
    end

    private

    def publicly_visible?(recording)
      return false unless defined?(RecordingStudioPublishable)

      recording.currently_published?
    end

    def public_layout
      return RecordingStudioPublishable.configuration.layout if defined?(RecordingStudioPublishable)

      "application"
    end
  end
end
