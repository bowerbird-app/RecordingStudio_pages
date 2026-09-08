# frozen_string_literal: true

module RecordingStudioPages
  class CtaRegistry
    def initialize
      @definitions = {}.freeze
      @mutex = Mutex.new
    end

    def register(**attributes)
      definition = CtaDefinition.new(**attributes)
      @mutex.synchronize { store!(definition) }
      definition
    end

    def fetch(key)
      definitions.fetch(key.to_s)
    rescue KeyError
      raise UnknownCtaType, "Unknown call to action #{key.inspect}"
    end

    def find(key)
      definitions[key.to_s]
    end

    def all
      definitions.values.sort_by { |definition| [definition.name, definition.key] }
    end

    def keys
      definitions.keys.sort
    end

    def catalog
      all.map(&:catalog)
    end

    def clear!
      @mutex.synchronize { @definitions = {}.freeze }
    end

    private

    attr_reader :definitions

    def store!(definition)
      if definitions.key?(definition.key)
        owner = definitions.fetch(definition.key).source || "unknown"
        raise DuplicateRegistration,
              "Call to action #{definition.key.inspect} is already registered by #{owner.inspect}"
      end

      @definitions = definitions.merge(definition.key => definition).freeze
    end
  end
end
