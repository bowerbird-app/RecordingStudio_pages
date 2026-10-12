# frozen_string_literal: true

begin
  require "recording_studio_publishable"
rescue LoadError
end
begin
  require "recording_studio_orderable"
rescue LoadError
end
begin
  require "recording_studio_trashable"
rescue LoadError
end

module RecordingStudioPages
  class Page < ApplicationRecord
    include RecordingStudio::Recordable

    self.table_name = "recording_studio_pages_pages"

    LABEL = "Page"
    PLURAL_LABEL = "Pages"

    parent_types = if RecordingStudioPages.respond_to?(:page_parent_types)
                     RecordingStudioPages.page_parent_types
                   else
                     %w[Workspace Folder]
                   end

    # recording_studio_recordable captures label at class load; keep English here.
    recording_studio_recordable label: LABEL,
                                plural_label: PLURAL_LABEL,
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

    include RecordingStudio::Capabilities::Trashable.to if defined?(RecordingStudio::Capabilities::Trashable)

    def self.recordable_type_label
      Copy.t("recordables.page.label", default: LABEL)
    end

    class << self
      alias recording_studio_type_label recordable_type_label
    end

    def homepage?
      homepage == true
    end
  end
end
