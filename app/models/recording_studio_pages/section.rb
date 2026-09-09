# frozen_string_literal: true

begin
  require "recording_studio_duplicatable"
rescue LoadError
end
begin
  require "recording_studio_attachable"
rescue LoadError
end

module RecordingStudioPages
  class Section < ApplicationRecord
    include RecordingStudio::Recordable

    self.table_name = "recording_studio_pages_sections"

    recording_studio_recordable label: "Section",
                                plural_label: "Sections",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPages::Page"]

    if defined?(RecordingStudio::Capabilities::Duplicatable)
      include RecordingStudio::Capabilities::Duplicatable.to(
        prefix: nil,
        suffix: nil
      )
    end

    if defined?(RecordingStudio::Capabilities::Attachable)
      include RecordingStudio::Capabilities::Attachable.to(
        allowed_content_types: ["image/*"],
        enabled_attachment_kinds: %i[image]
      )
    end

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
