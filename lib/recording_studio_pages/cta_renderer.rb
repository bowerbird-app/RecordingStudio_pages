# frozen_string_literal: true

module RecordingStudioPages
  class CtaRenderer
    def self.call(view, raw)
      new(view, raw).call
    end

    def initialize(view, raw)
      @view = view
      @raw = raw
    end

    def call
      return if type.blank?
      return unless definition
      return unless component_class

      render_cta
    rescue StandardError => e
      logger&.warn("[recording_studio_pages] cta #{type} failed: #{e.class}: #{e.message}")
      nil
    end

    private

    def render_cta
      html = @view.render(component_class.new(cta: payload))
      html.presence
    end

    def type
      payload["type"].to_s
    end

    def definition
      @definition ||= RecordingStudioPages.find_cta(type)
    end

    def component_class
      definition&.resolve_component
    end

    def payload
      @payload ||= @raw.is_a?(Hash) ? @raw.to_h.stringify_keys : {}
    end

    def logger
      return unless defined?(Rails)

      Rails.logger
    end
  end
end
