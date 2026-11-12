# frozen_string_literal: true

require_relative "documentation"
require_relative "section_docs"
require_relative "errors"
require_relative "lookup"

module RecordingStudioPages
  module Api
    module Endpoints
      CATALOG_NAME = "pages.catalog"
      ADD_NAME = "sections.add"
      DUPLICATE_NAME = "sections.duplicate"
      TOGGLE_NAME = "sections.toggle"
      EMPTY_CONTRACT = { reject_unknown: false, fields: {} }.freeze
      ADD_CONTRACT = { reject_unknown: false, fields: SectionDocs::ADD_FIELDS }.freeze
      TOGGLE_CONTRACT = { reject_unknown: false, fields: SectionDocs::TOGGLE_FIELDS }.freeze

      module_function

      def register!(api)
        register_catalog(api)
        register_add_section(api)
        register_duplicate_section(api)
        register_toggle_section(api)
      end

      def register_catalog(api)
        register_endpoint(
          api,
          CATALOG_NAME,
          http_verb: :get,
          path: "pages_catalog",
          handler: Catalog,
          serializer: nil,
          openapi: SectionDocs::CATALOG,
          input_contract: EMPTY_CONTRACT
        )
      end

      def register_add_section(api)
        register_endpoint(
          api,
          ADD_NAME,
          http_verb: :post,
          path: "page_sections/:id/add",
          handler: AddSection,
          serializer: recording_serializer,
          openapi: SectionDocs::ADD,
          input_contract: ADD_CONTRACT
        )
      end

      def register_duplicate_section(api)
        register_endpoint(
          api,
          DUPLICATE_NAME,
          http_verb: :post,
          path: "page_sections/:id/duplicate",
          handler: DuplicateSection,
          serializer: recording_serializer,
          openapi: SectionDocs::DUPLICATE,
          input_contract: EMPTY_CONTRACT
        )
      end

      def register_toggle_section(api)
        register_endpoint(
          api,
          TOGGLE_NAME,
          http_verb: :post,
          path: "page_sections/:id/toggle",
          handler: ToggleSection,
          serializer: recording_serializer,
          openapi: SectionDocs::TOGGLE,
          input_contract: TOGGLE_CONTRACT
        )
      end

      def register_endpoint(api, name, **)
        return if ::RecordingStudioApi.registered_endpoint(name, api: api)

        ::RecordingStudioApi.register_endpoint(name, api: api, **)
      end

      def recording_serializer
        ::RecordingStudioApi::Serializers::ResourceRecordingSerializer
      end

      class Catalog
        def self.call(context)
          context.access_grant.authorize!(recording: context.root_recording, role: :view)
          RecordingStudioPages.catalog
        end
      end

      class AddSection
        def self.call(context)
          parent = Lookup.find!(context, context.params[:id], types: [Lookup::PAGE_TYPE, Lookup::SECTION_TYPE])
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
            actor: Lookup.actor(context)
          }
        end
        private_class_method :add_arguments
      end

      class DuplicateSection
        def self.call(context)
          section = Lookup.find!(context, context.params[:id], types: [Lookup::SECTION_TYPE])
          context.access_grant.authorize!(recording: section, role: :edit)
          Errors.unwrap(
            Services::DuplicateSection.call(section_recording: section, actor: Lookup.actor(context))
          )
        end
      end

      class ToggleSection
        def self.call(context)
          section = Lookup.find!(context, context.params[:id], types: [Lookup::SECTION_TYPE])
          context.access_grant.authorize!(recording: section, role: :edit)
          Errors.unwrap(
            Services::ToggleSection.call(
              section_recording: section,
              enabled: context.params[:enabled],
              actor: Lookup.actor(context)
            )
          )
        end
      end
    end
  end
end
