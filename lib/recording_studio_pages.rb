# frozen_string_literal: true

require "recording_studio"
require "view_component"
require "recording_studio_pages/version"
require "recording_studio_pages/errors"
require "recording_studio_pages/configuration"
require "recording_studio_pages/field_schema"
require "recording_studio_pages/section_definition"
require "recording_studio_pages/section_registry"
require "recording_studio_pages/page_template"
require "recording_studio_pages/template_registry"
require "recording_studio_pages/composition"
require "recording_studio_pages/renderer"
require "recording_studio_pages/built_ins"
require "recording_studio_pages/services/base"
require "recording_studio_pages/services/clear_other_homepages"
require "recording_studio_pages/services/create_page"
require "recording_studio_pages/services/revise_page"
require "recording_studio_pages/services/append_section_order"
require "recording_studio_pages/services/add_section"
require "recording_studio_pages/services/revise_section"
require "recording_studio_pages/services/reorder_sections"
require "recording_studio_pages/services/move_section"
require "recording_studio_pages/services/toggle_section"
require "recording_studio_pages/services/duplicate_section"
require "recording_studio_pages/services/trash_recording"
require "recording_studio_pages/services/remove_section"
require "recording_studio_pages/services/remove_page"
require "recording_studio_pages/services/apply_template"
require "recording_studio_pages/engine"

module RecordingStudioPages
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
      configuration
    end

    def section_registry
      @section_registry ||= SectionRegistry.new
    end

    def template_registry
      @template_registry ||= TemplateRegistry.new
    end

    def register_section(**attributes)
      section_registry.register(**attributes)
    end

    def section(key)
      section_registry.fetch(key)
    end

    def find_section(key)
      section_registry.find(key)
    end

    def section?(key)
      find_section(key).present?
    end

    def sections
      section_registry.all
    end

    def register_template(**attributes)
      template_registry.register(**attributes)
    end

    def template(key)
      template_registry.fetch(key)
    end

    def templates
      template_registry.all
    end

    def catalog
      {
        sections: section_registry.catalog,
        templates: template_registry.catalog
      }
    end

    def reset!
      section_registry.clear!
      template_registry.clear!
    end

    def page_parent_types
      Array(configuration.page_parent_types).map(&:to_s)
    end

    def homepage_path
      configuration.homepage_path.presence || "/"
    end

    # Named Flatpack theme on public pages. Hosts set this once:
    # `FlatPack.configuration.default_theme`. Dummy uses `rounded`.
    def theme
      normalize_theme(flatpack_default_theme)
    end

    def normalize_theme(name)
      normalized = name.to_s.strip.downcase.tr("_", "-").gsub(/[^a-z0-9-]/, "")
      normalized.presence || "rounded"
    end

    def flatpack_default_theme
      return unless defined?(FlatPack)
      return unless FlatPack.respond_to?(:configuration)

      config = FlatPack.configuration
      return unless config.respond_to?(:default_theme)

      config.default_theme
    end

    def page_parent?(recording)
      recording.present? && page_parent_types.include?(recording.recordable_type.to_s)
    end
  end
end
