# frozen_string_literal: true

require_relative "documentation"

module RecordingStudioPages
  module Api
    module SectionDocs
      CONTENT = {
        type: "object",
        description: "Section copy. The catalog for this section type decides which keys are valid."
      }.freeze
      SETTINGS = {
        type: "object",
        description: "Section layout settings. The catalog for this section type decides which keys are valid."
      }.freeze
      OPENAPI = {
        update: {
          title: "Section - Revise",
          summary: "Section - Revise",
          description: "Updates a section's copy and settings. " \
                       "The Pages catalog validates those fields. " \
                       "Same access as Update on a section: Accessible :edit on the section.",
          request_body: Documentation.json_body(content: CONTENT, settings: SETTINGS)
        }
      }.freeze
      CATALOG = {
        title: "Page - Catalog",
        summary: "Page - Catalog",
        description: "Lists registered section and call-to-action types, including field schemas. " \
                     "Same access as opening the page builder: Accessible :view on the grant's root.",
        tags: ["Pages"]
      }.freeze
      ADD = {
        title: "Section - Add",
        summary: "Section - Add",
        description: "Adds a section under a page or parent section. The path id is that parent. " \
                     "Section type and fields are checked by the Pages catalog, not a second schema. " \
                     "Same access as adding a section in the builder: Accessible :edit on the parent.",
        tags: ["Pages"]
      }.freeze
      DUPLICATE = {
        title: "Section - Duplicate",
        summary: "Section - Duplicate",
        description: "Copies a section in place, including child sections and pictures. " \
                     "Same access as Copy in the builder: Accessible :edit on the section.",
        tags: ["Pages"]
      }.freeze
      TOGGLE = {
        title: "Section - Toggle",
        summary: "Section - Toggle",
        description: "Turns a section on or off. Same access as the builder toggle: " \
                     "Accessible :edit on the section.",
        tags: ["Pages"]
      }.freeze
      ADD_FIELDS = {
        section_type: {
          type: :string,
          required: true,
          allow_blank: false,
          description: "Registered section key, such as hero or rich_text."
        },
        content: {
          type: :hash,
          required: false,
          description: "Section copy. The catalog for section_type decides which keys are valid."
        },
        settings: {
          type: :hash,
          required: false,
          description: "Section layout settings. The catalog for section_type decides which keys are valid."
        },
        enabled: {
          type: :boolean,
          required: false,
          description: "Whether the section is on. Defaults to true."
        }
      }.freeze
      TOGGLE_FIELDS = {
        enabled: {
          type: :boolean,
          required: true,
          description: "True shows the section on the page. False keeps it off the public page."
        }
      }.freeze
    end
  end
end
