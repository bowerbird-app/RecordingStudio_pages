# frozen_string_literal: true

module RecordingStudio
  module Capabilities
    module PageSections
      def self.to
        RecordingStudio::Capabilities.include_for(:page_sections)
      end
    end
  end
end

RecordingStudio.register_capability(:page_sections, source: "recording_studio_pages")
