# frozen_string_literal: true

module RecordingStudioPages
  class Section < ApplicationRecord
    include RecordingStudio::Recordable

    self.table_name = "recording_studio_pages_sections"

    recording_studio_recordable label: "Section",
                                plural_label: "Sections",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPages::Page"]

    def enabled?
      enabled != false
    end

    def definition
      RecordingStudioPages.find_section(section_type)
    end

    def known?
      definition.present?
    end
  end
end
