# frozen_string_literal: true

require_relative "api/documentation"
require_relative "api/page_docs"
require_relative "api/section_docs"
require_relative "api/page_resource"
require_relative "api/section_resource"
require_relative "api/endpoints"

module RecordingStudioPages
  module Api
    PAGE_TYPE = "RecordingStudioPages::Page"
    SECTION_TYPE = "RecordingStudioPages::Section"
    PAGE_TYPE_API = {
      operations: %i[create update],
      auto_capability_actions: false,
      capability_actions: [],
      output_keys: %i[title homepage],
      writable_attributes: %i[title homepage],
      openapi: PageDocs::OPENAPI
    }.freeze
    SECTION_TYPE_API = {
      operations: %i[update],
      auto_capability_actions: false,
      capability_actions: [],
      output_keys: %i[section_type content settings enabled],
      writable_attributes: %i[content settings],
      openapi: SectionDocs::OPENAPI
    }.freeze

    module_function

    def register!
      return unless defined?(::RecordingStudioApi)

      each_api { |api| register_api(api) }
    end

    def register_api(api)
      register_page_type(api)
      register_section_type(api)
      register_page_handlers(api)
      register_section_handlers(api)
      Endpoints.register!(api)
    end

    def register_page_type(api)
      return if ::RecordingStudioApi.recordable_registration_for(PAGE_TYPE, api: api)

      ::RecordingStudioApi.register_recordable_type_api(
        PAGE_TYPE,
        api: api,
        serializer: method(:serialize_page),
        **PAGE_TYPE_API
      )
    end

    def register_section_type(api)
      return if ::RecordingStudioApi.recordable_registration_for(SECTION_TYPE, api: api)

      ::RecordingStudioApi.register_recordable_type_api(
        SECTION_TYPE,
        api: api,
        serializer: method(:serialize_section),
        **SECTION_TYPE_API
      )
    end

    def register_page_handlers(api)
      { create: PageResource::Create, update: PageResource::Update }.each do |action, handler|
        next if ::RecordingStudioApi.resource_handler(PAGE_TYPE, action, api: api)

        ::RecordingStudioApi.register_resource_handler(PAGE_TYPE, action, api: api, handler: handler)
      end
    end

    def register_section_handlers(api)
      return if ::RecordingStudioApi.resource_handler(SECTION_TYPE, :update, api: api)

      ::RecordingStudioApi.register_resource_handler(
        SECTION_TYPE,
        :update,
        api: api,
        handler: SectionResource::Update
      )
    end

    def serialize_page(page, **)
      { title: page.title, homepage: page.homepage? }
    end

    def serialize_section(section, **)
      {
        section_type: section.section_type,
        content: section.content,
        settings: section.settings,
        enabled: section.enabled?
      }
    end

    def each_api
      if named_api_registration_supported?
        ::RecordingStudioApi.configuration.each_api { |definition| yield definition.name }
      else
        yield :public
      end
    end

    def named_api_registration_supported?
      ::RecordingStudioApi.respond_to?(:configuration) &&
        ::RecordingStudioApi.configuration.respond_to?(:each_api) &&
        accepts_api_keyword?(:register_recordable_type_api) &&
        accepts_api_keyword?(:register_endpoint) &&
        accepts_api_keyword?(:register_resource_handler)
    end

    def accepts_api_keyword?(method_name)
      return false unless ::RecordingStudioApi.respond_to?(method_name)

      ::RecordingStudioApi.method(method_name).parameters.any? do |type, name|
        type == :keyrest || (name == :api && %i[key keyreq].include?(type))
      end
    end
  end
end
