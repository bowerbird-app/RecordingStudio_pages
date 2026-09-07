# frozen_string_literal: true

begin
  require "recording_studio_publishable"
rescue LoadError
end
begin
  require "recording_studio_orderable"
rescue LoadError
end

module RecordingStudioPages
  class Page < ApplicationRecord
    include RecordingStudio::Recordable

    self.table_name = "recording_studio_pages_pages"

    parent_types = if RecordingStudioPages.respond_to?(:page_parent_types)
                     RecordingStudioPages.page_parent_types
                   else
                     %w[Workspace Folder]
                   end

    recording_studio_recordable label: "Page",
                                plural_label: "Pages",
                                root: false,
                                allowed_parent_types: parent_types

    if defined?(RecordingStudio::Capabilities::Publishable)
      include RecordingStudio::Capabilities::Publishable.to(
        public_controller: "recording_studio_pages/published_pages",
        public_action: :show,
        public_layout: "recording_studio_pages/public",
        path: "/pages/:uuid/:slug",
        schedule: true,
        seo: true
      )
    end

    if defined?(RecordingStudio::Capabilities::Orderable)
      include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioPages::Section"])
    end

    def homepage?
      homepage == true
    end
  end
end
