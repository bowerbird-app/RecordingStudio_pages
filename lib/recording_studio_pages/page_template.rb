# frozen_string_literal: true

module RecordingStudioPages
  class PageTemplate
    attr_reader :key, :name, :sections, :source

    def initialize(key:, name:, sections:, source: nil)
      @key = key.to_s
      @name = name.to_s
      @sections = Array(sections).map { |entry| normalize_entry(entry) }.freeze
      @source = source
    end

    def catalog
      {
        key: key,
        name: name,
        sections: sections,
        source: source
      }
    end

    private

    def normalize_entry(entry)
      hash = entry.is_a?(Hash) ? entry.transform_keys(&:to_sym) : { type: entry }
      {
        "type" => hash.fetch(:type).to_s,
        "content" => (hash[:content] || {}).to_h,
        "settings" => (hash[:settings] || {}).to_h,
        "enabled" => hash.key?(:enabled) ? hash[:enabled] : true
      }
    end
  end
end
