# frozen_string_literal: true

module RecordingStudioPages
  class CtaDefinition
    ATTRIBUTES = %i[key name component fields source].freeze

    attr_reader(*ATTRIBUTES)

    def initialize(key:, name:, component:, fields: {}, source: nil)
      @key = key.to_s
      @name = name.to_s
      @component = component
      @fields = FieldSchema.new(fields)
      @source = source
    end

    def catalog
      {
        key: key,
        name: name,
        fields: fields.catalog,
        source: source
      }
    end

    def resolve_component
      return component if component.respond_to?(:new)
      return component.constantize if component.respond_to?(:constantize)

      component.to_s.safe_constantize
    end
  end
end
