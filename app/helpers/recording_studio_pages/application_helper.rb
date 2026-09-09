# frozen_string_literal: true

module RecordingStudioPages
  module ApplicationHelper
    def recording_studio_pages_nav(title:, back_url: nil)
      if respond_to?(:recording_studio_pages_page_nav)
        recording_studio_pages_page_nav(title: title, back_url: back_url)
      elsif respond_to?(:recording_studio_page_nav)
        recording_studio_page_nav(title: title, page_nav_back_url: back_url)
      end
    end
  end
end
