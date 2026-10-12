# frozen_string_literal: true

begin
  require "recording_studio_duplicatable"
rescue LoadError
end
begin
  require "recording_studio_attachable"
rescue LoadError
end
begin
  require "recording_studio_orderable"
rescue LoadError
end

module RecordingStudioPages
  class Section < ApplicationRecord
    include RecordingStudio::Recordable

    self.table_name = "recording_studio_pages_sections"

    LABEL = "Section"
    PLURAL_LABEL = "Sections"

    # recording_studio_recordable captures label at class load; keep English here.
    recording_studio_recordable label: LABEL,
                                plural_label: PLURAL_LABEL,
                                root: false,
                                allowed_parent_types: ["RecordingStudioPages::Page", "RecordingStudioPages::Section"]

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

    if defined?(RecordingStudio::Capabilities::Orderable)
      include RecordingStudio::Capabilities::Orderable.to(allows: ["RecordingStudioPages::Section"])
    end

    def self.recordable_type_label
      Copy.t("recordables.section.label", default: LABEL)
    end

    class << self
      alias recording_studio_type_label recordable_type_label
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
