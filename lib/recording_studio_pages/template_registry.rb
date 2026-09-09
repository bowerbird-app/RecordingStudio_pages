# frozen_string_literal: true

module RecordingStudioPages
  class TemplateRegistry
    def initialize
      @templates = {}.freeze
      @mutex = Mutex.new
    end

    def register(**attributes)
      template = PageTemplate.new(**attributes)
      @mutex.synchronize { store!(template) }
      template
    end

    def fetch(key)
      templates.fetch(key.to_s)
    rescue KeyError
      raise UnknownTemplate, "Unknown page template #{key.inspect}"
    end

    def find(key)
      templates[key.to_s]
    end

    def all
      templates.values.sort_by { |template| [template.name, template.key] }
    end

    def catalog
      all.map(&:catalog)
    end

    def clear!
      @mutex.synchronize { @templates = {}.freeze }
    end

    private

    attr_reader :templates

    def store!(template)
      if templates.key?(template.key)
        owner = templates.fetch(template.key).source || "unknown"
        raise DuplicateRegistration,
              "Page template #{template.key.inspect} is already registered by #{owner.inspect}"
      end

      @templates = templates.merge(template.key => template).freeze
    end
  end
end
