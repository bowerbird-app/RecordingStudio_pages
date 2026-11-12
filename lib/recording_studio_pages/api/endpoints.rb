# frozen_string_literal: true

require_relative "documentation"
require_relative "section_docs"
require_relative "errors"

module RecordingStudioPages
  module Api
    module Endpoints
      CATALOG_NAME = "pages.catalog"
      CAPABILITY = :page_sections
      EMPTY_CONTRACT = { reject_unknown: false, fields: {} }.freeze
      ADD_CONTRACT = { reject_unknown: false, fields: SectionDocs::ADD_FIELDS }.freeze
      TOGGLE_CONTRACT = { reject_unknown: false, fields: SectionDocs::TOGGLE_FIELDS }.freeze

      module_function

      def register!(api)
        register_catalog(api)
        section_actions.each { |action| register_capability_action(api, action.fetch(:name), **action.except(:name)) }
      end

      def register_catalog(api)
        return if ::RecordingStudioApi.registered_endpoint(CATALOG_NAME, api: api.name)

        ::RecordingStudioApi.register_endpoint(CATALOG_NAME, **catalog_endpoint(api))
      end

      def catalog_endpoint(api)
        {
          api: api.name,
          http_verb: :get,
          path: "pages_catalog",
          handler: Catalog,
          serializer: nil,
          openapi: SectionDocs::CATALOG,
          input_contract: EMPTY_CONTRACT
        }
      end

      def register_capability_action(api, name, handler:, **)
        existing = ::RecordingStudioApi.capability_action(name, api: api.name)
        return if existing&.handler == handler

        ::RecordingStudioApi.register_capability_action(
          name,
          api: api.name,
          capability: CAPABILITY,
          required_role: :edit,
          handler: handler,
          **
        )
      end

      def section_actions
        [
          { name: :page_sections_add, handler: AddSection, openapi: SectionDocs::ADD,
            input_contract: ADD_CONTRACT },
          { name: :page_sections_duplicate, handler: DuplicateSection, openapi: SectionDocs::DUPLICATE,
            input_contract: EMPTY_CONTRACT },
          { name: :page_sections_toggle, handler: ToggleSection, openapi: SectionDocs::TOGGLE,
            input_contract: TOGGLE_CONTRACT }
        ]
      end

      class Catalog
        def self.call(context)
          context.access_grant.authorize!(recording: context.root_recording, role: :view)
          RecordingStudioPages.catalog
        end
      end

      class AddSection
        def self.call(context)
          parent = context.recording
          context.access_grant.authorize!(recording: parent, role: :edit)
          Errors.unwrap(Services::AddSection.call(**add_arguments(parent, context)))
        end

        def self.add_arguments(parent, context)
          {
            parent_recording: parent,
            section_type: context.params[:section_type],
            content: context.params[:content] || {},
            settings: context.params[:settings] || {},
            enabled: context.params.key?(:enabled) ? context.params[:enabled] : true,
            actor: context.actor
          }
        end
        private_class_method :add_arguments
      end

      class DuplicateSection
        def self.call(context)
          section = context.recording
          context.access_grant.authorize!(recording: section, role: :edit)
          Errors.unwrap(
            Services::DuplicateSection.call(section_recording: section, actor: context.actor)
          )
        end
      end

      class ToggleSection
        def self.call(context)
          section = context.recording
          context.access_grant.authorize!(recording: section, role: :edit)
          Errors.unwrap(
            Services::ToggleSection.call(
              section_recording: section,
              enabled: context.params[:enabled],
              actor: context.actor
            )
          )
        end
      end
    end
  end
end
