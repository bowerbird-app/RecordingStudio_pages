# frozen_string_literal: true

require "uri"

module RecordingStudioPages
  class FieldSchema
    SIMPLE_TYPES = %i[string text rich_text url boolean integer attachment].freeze
    COMPOSITE_TYPES = %i[link list recording_ids cta].freeze
    RECORDING_ID = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

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

    def upgrade_legacy_attachments(raw)
      upgrade_attachment_hash(stringify_keys(raw), fields)
    end

    def remap_attachments(raw, mapping)
      transform(raw) do |spec, value|
        next value unless spec[:type].to_sym == :attachment

        mapped = mapping[value.to_s]
        mapped.presence || value
      end
    end

    def resolve_attachments(raw, recording:, context: nil)
      transform(raw) do |spec, value|
        next value unless spec[:type].to_sym == :attachment

        AttachmentUrl.call(value, recording: recording, context: context)
      end
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
      when :cta
        coerce_cta(value)
      when :list
        Array(value).filter_map { |item| read_list_item(spec, item) }
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

    def read_list_item(spec, value)
      hash = stringify_keys(value)
      return if destroyed_item?(hash)

      item = coerce_item(spec[:item] || {}, hash.except("_destroy"))
      return if blank_item?(item)

      item
    end

    def destroyed_item?(hash)
      %w[1 true yes].include?(hash["_destroy"].to_s.downcase)
    end

    def blank_item?(item)
      item.values.all? { |value| value.nil? || value == "" || value == [] || value == { "text" => "", "url" => "" } }
    end

    def default_for(spec)
      case spec[:type].to_sym
      when :list, :recording_ids then []
      when :link then { "text" => "", "url" => "" }
      when :cta then { "type" => "" }
      when :boolean then false
      else
        spec[:default]
      end
    end

    def validate_value(key, spec, value)
      return ["#{key} is required"] if spec[:required] && blank_value?(spec, value)

      type = spec[:type].to_sym
      return url_error(key) if type == :url && value.present? && !safe_url?(value)
      return ["#{key} must be true or false"] unless boolean_ok?(spec, value)
      return ["#{key} must be an integer"] unless integer_ok?(spec, value)
      return validate_link(key, value) if type == :link
      return validate_cta(key, value) if type == :cta
      return validate_list(key, spec, value) if type == :list
      return validate_recording_ids(key, value) if type == :recording_ids
      return validate_attachment(key, value) if type == :attachment

      []
    end

    def boolean_ok?(spec, value)
      return true unless spec[:type].to_sym == :boolean

      value.nil? || [true, false, "true", "false", "1", "0"].include?(value)
    end

    def integer_ok?(spec, value)
      return true unless spec[:type].to_sym == :integer
      return true if value.blank?

      !Integer(value, exception: false).nil?
    end

    def url_error(key)
      ["#{key} must be a URL"]
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
      when :cta
        coerce_cta(value)["type"].blank?
      else
        value.nil? || value.to_s.strip.empty?
      end
    end

    def validate_recording_ids(key, value)
      return ["#{key} must be a list of recording ids"] unless value.nil? || value.is_a?(Array)

      []
    end

    def coerce_cta(value)
      hash = stringify_keys(value)
      type = hash["type"].to_s
      type = "button" if type.blank? && (hash["text"].present? || hash["url"].present?)
      payload = { "type" => type }
      return payload if type.blank?

      definition = RecordingStudioPages.find_cta(type)
      unless definition
        hash.each do |nested_key, nested|
          payload[nested_key] = nested unless nested_key == "type"
        end
        return payload
      end

      payload.merge(definition.fields.read(hash))
    end

    def validate_cta(key, value)
      hash = coerce_cta(value)
      type = hash["type"].to_s
      return [] if type.blank?

      definition = RecordingStudioPages.find_cta(type)
      return [] unless definition

      definition.fields.validate(hash.except("type")).map { |error| "#{key}.#{error}" }
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
        hash = stringify_keys(item)
        next [] if destroyed_item?(hash)

        cleaned = hash.except("_destroy")
        next [] if blank_item?(coerce_item(spec[:item] || {}, cleaned))

        self.class.new(spec[:item] || {}).validate(cleaned).map { |error| "#{key}[#{index}].#{error}" }
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
      catalog[:label] = spec[:label] if spec[:label]
      catalog[:kind] = spec[:kind].to_s if spec[:kind]
      catalog
    end

    def validate_attachment(key, value)
      return [] if value.blank?

      text = value.to_s.strip
      return [] if safe_url?(text)
      return [] if text.match?(RECORDING_ID)

      ["#{key} must be an image or a URL"]
    end

    def upgrade_attachment_hash(source, specs)
      result = source.dup
      specs.each do |key, spec|
        key_s = key.to_s
        type = spec[:type].to_sym
        if type == :attachment
          result[key_s] = result[key_s].presence || result["#{key_s}_url"]
        elsif type == :list
          nested = self.class.new(spec[:item] || {}).fields
          result[key_s] = Array(result[key_s]).map do |item|
            upgrade_attachment_hash(stringify_keys(item), nested)
          end
        end
      end
      result
    end

    def transform(raw)
      transform_hash(stringify_keys(raw), fields) { |spec, value| yield spec, value }
    end

    def transform_hash(hash, specs)
      result = hash.dup
      specs.each do |key, spec|
        key_s = key.to_s
        type = spec[:type].to_sym
        result[key_s] = if type == :list
                          nested = self.class.new(spec[:item] || {}).fields
                          Array(result[key_s]).map do |item|
                            transform_hash(stringify_keys(item), nested) { |nested_spec, value| yield nested_spec, value }
                          end
                        else
                          yield(spec, result[key_s])
                        end
      end
      result
    end
  end
end
