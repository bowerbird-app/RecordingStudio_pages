# frozen_string_literal: true

require_relative "documentation"

module RecordingStudioPages
  module Api
    module PageDocs
      TITLE = { type: "string", description: "Page name shown in the builder and on the public page." }.freeze
      HOMEPAGE = {
        type: "boolean",
        description: "True makes this the public home page for the workspace."
      }.freeze
      OPENAPI = {
        create: {
          title: "Page - Create",
          summary: "Page - Create",
          description: "Creates a page under a workspace or folder. " \
                       "Same access as the new-page form: Accessible :edit on the parent.",
          request_body: Documentation.json_body(
            parent_id: {
              type: "string",
              description: "Workspace or folder recording id to parent the page under."
            },
            title: TITLE,
            homepage: HOMEPAGE
          )
        },
        update: {
          title: "Page - Revise",
          summary: "Page - Revise",
          description: "Renames a page or sets it as home. " \
                       "Same access as saving page settings: Accessible :edit on the page.",
          request_body: Documentation.json_body(title: TITLE, homepage: HOMEPAGE)
        }
      }.freeze
    end
  end
end
