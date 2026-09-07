# frozen_string_literal: true

module RecordingStudioPages
  class PublishedPagesController < ApplicationController
    skip_before_action :authenticate_user!, raise: false

    def show
      @page_recording = @parent_recording || @recording
      @page = @parent_recordable || @recordable || @page_recording&.recordable
      return head :not_found unless @page_recording

      @rendered_sections = Renderer.call(@page_recording, context: self)
    end
  end
end
