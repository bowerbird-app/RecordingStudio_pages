# frozen_string_literal: true

module RecordingStudioPages
  class SectionDefinition
    ATTRIBUTES = %i[
      key name category component fields settings variants validations data source
    ].freeze

    attr_reader(*ATTRIBUTES)

    def initialize(key:, name:, component:, category: "content", fields: {}, settings: {}, variants: [],
                   validations: [], data: nil, source: nil)
      @key = key.to_s
      @name = name.to_s
      @category = category.to_s
      @component = component
      @fields = FieldSchema.new(fields)
      @settings = FieldSchema.new(settings)
      @variants = Array(variants).map(&:to_s)
      @validations = Array(validations)
      @data = data
      @source = source
    end

    def read_content(raw)
      fields.read(raw)
    end

    def read_settings(raw)
      values = settings.read(raw)
      values["variant"] = normalize_variant(values["variant"]) if variants.any?
      values
    end

    def validate_payload(content:, settings:)
      errors = []
      errors.concat(fields.validate(content))
      errors.concat(self.settings.validate(settings))
      errors.concat(validate_variant(settings))
      errors.concat(run_custom_validations(content, settings))
      errors
    end

    def catalog
      {
        key: key,
        name: name,
        category: category,
        fields: fields.catalog,
        settings: settings.catalog,
        variants: variants,
        source: source
      }
    end

    def resolve_component
      return component if component.respond_to?(:new)
      return component.constantize if component.respond_to?(:constantize)

      component.to_s.safe_constantize
    end

    def starter_content
      fields.fields.each_with_object({}) do |(key, spec), content|
        next unless spec[:required]
        next unless %i[string text rich_text].include?(spec[:type].to_sym)

        content[key.to_s] = name
      end
    end

    private

    def normalize_variant(value)
      text = value.to_s
      return variants.first if text.blank?
      return text if variants.include?(text)

      variants.first
    end

    def validate_variant(settings)
      return [] if variants.empty?

      variant = stringify_keys(settings)["variant"].to_s
      return [] if variant.blank? || variants.include?(variant)

      ["variant must be one of: #{variants.join(', ')}"]
    end

    def run_custom_validations(content, settings)
      validations.filter_map do |validator|
        validator.call(content, settings)
      rescue StandardError => e
        e.message
      end
    end

    def stringify_keys(raw)
      raw.to_h.transform_keys(&:to_s)
    end
  end
end
