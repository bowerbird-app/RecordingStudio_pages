# frozen_string_literal: true

module RecordingStudioPages
  class FieldSchema
    SIMPLE_TYPES = %i[string text rich_text url boolean integer attachment].freeze
    COMPOSITE_TYPES = %i[link list recording_ids].freeze

    def initialize(fields)
      @fields = normalize(fields)
    end

    attr_reader :fields

    def keys
      fields.keys
    end

    def read(raw)
      source = stringify_keys(raw)
      fields.each_with_object({}) do |(key, spec), result|
        result[key.to_s] = coerce_value(spec, source[key.to_s])
      end
    end

    def validate(raw)
      source = stringify_keys(raw)
      errors = []
      fields.each do |key, spec|
        errors.concat(validate_value(key, spec, source[key.to_s]))
      end
      extra = source.keys - fields.keys.map(&:to_s)
      extra.each { |key| errors << "#{key} is not a registered field" }
      errors
    end

    def catalog
      fields.transform_values { |spec| catalog_spec(spec) }
    end

    private

    def normalize(fields)
      (fields || {}).each_with_object({}) do |(key, spec), result|
        result[key.to_sym] = normalize_spec(spec)
      end
    end

    def normalize_spec(spec)
      return { type: spec.to_sym } if spec.is_a?(Symbol) || spec.is_a?(String)
      return spec.transform_keys(&:to_sym) if spec.is_a?(Hash)

      raise ArgumentError, "Unsupported field spec #{spec.inspect}"
    end

    def stringify_keys(raw)
      return {} if raw.nil?

      raw.to_h.transform_keys(&:to_s)
    end

    def coerce_value(spec, value)
      case spec[:type].to_sym
      when :boolean
        value == true || value.to_s == "true" || value.to_s == "1"
      when :integer
        value.nil? || value == "" ? nil : Integer(value, exception: false)
      when :link
        coerce_link(value)
      when :list
        Array(value).map { |item| coerce_item(spec[:item] || {}, item) }
      when :recording_ids
        ids = value.is_a?(String) ? value.split(/[\s,]+/) : Array(value)
        ids.map(&:to_s).reject(&:blank?)
      when :attachment
        value.to_s.presence
      else
        value.nil? ? default_for(spec) : value
      end
    end

    def coerce_link(value)
      hash = stringify_keys(value)
      { "text" => hash["text"].to_s, "url" => hash["url"].to_s }
    end

    def coerce_item(item_spec, value)
      schema = self.class.new(item_spec)
      schema.read(value)
    end

    def default_for(spec)
      case spec[:type].to_sym
      when :list, :recording_ids then []
      when :link then { "text" => "", "url" => "" }
      when :boolean then false
      else
        spec[:default]
      end
    end

    def validate_value(key, spec, value)
      return ["#{key} is required"] if spec[:required] && blank_value?(spec, value)

      type = spec[:type].to_sym
      return ["#{key} must be a URL"] if type == :url && value.present? && !safe_url?(value)
      return ["#{key} must be true or false"] if type == :boolean && !(value.nil? || [true, false, "true", "false", "1", "0"].include?(value))
      return ["#{key} must be an integer"] if type == :integer && value.present? && Integer(value, exception: false).nil?
      return validate_link(key, value) if type == :link
      return validate_list(key, spec, value) if type == :list
      return validate_recording_ids(key, value) if type == :recording_ids

      []
    end

    def blank_value?(spec, value)
      case spec[:type].to_sym
      when :boolean
        false
      when :list, :recording_ids
        Array(value).empty?
      when :link
        link = coerce_link(value)
        link["text"].blank? && link["url"].blank?
      else
        value.nil? || value.to_s.strip.empty?
      end
    end

    def validate_recording_ids(key, value)
      return ["#{key} must be a list of recording ids"] unless value.nil? || value.is_a?(Array)

      []
    end

    def validate_link(key, value)
      link = coerce_link(value)
      return [] if link["url"].blank?
      return [] if safe_url?(link["url"])

      ["#{key}.url must be a http, https, or relative path"]
    end

    def validate_list(key, spec, value)
      return ["#{key} must be a list"] unless value.nil? || value.is_a?(Array)

      Array(value).flat_map.with_index do |item, index|
        self.class.new(spec[:item] || {}).validate(item).map { |error| "#{key}[#{index}].#{error}" }
      end
    end

    def safe_url?(value)
      text = value.to_s.strip
      return true if text.start_with?("/")
      uri = URI.parse(text)
      %w[http https].include?(uri.scheme)
    rescue URI::InvalidURIError
      false
    end

    def catalog_spec(spec)
      catalog = { type: spec[:type].to_s }
      catalog[:item] = self.class.new(spec[:item]).catalog if spec[:item]
      catalog[:default] = spec[:default] if spec.key?(:default)
      catalog[:required] = true if spec[:required]
      catalog
    end
  end
end
