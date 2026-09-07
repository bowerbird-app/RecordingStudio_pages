# frozen_string_literal: true

module RecordingStudioPages
  class Configuration
    attr_accessor :page_parent_types, :homepage_path, :register_built_in_sections
    attr_reader :hooks

    def initialize
      @page_parent_types = %w[Workspace Folder]
      @homepage_path = "/"
      @register_built_in_sections = true
      @hooks = RecordingStudio::Hooks.new
    end

    def to_h
      {
        page_parent_types: Array(page_parent_types).map(&:to_s),
        homepage_path: homepage_path,
        register_built_in_sections: register_built_in_sections,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |key, value|
        setter = "#{key}="
        public_send(setter, value) if respond_to?(setter)
      end
    end
  end
end
