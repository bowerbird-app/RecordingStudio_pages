# frozen_string_literal: true

module RecordingStudioPages
  class RenderedSection
    attr_reader :recording, :recordable, :definition, :content, :settings, :data

    def initialize(recording:, definition:, content:, settings:, data: nil)
      @recording = recording
      @recordable = recording.recordable
      @definition = definition
      @content = content
      @settings = settings
      @data = data
    end

    def component_class
      definition.resolve_component
    end
  end

  class Renderer
    def self.call(page_recording, context: nil)
      new(page_recording, context: context).call
    end

    def initialize(page_recording, context: nil)
      @page_recording = page_recording
      @context = context
    end

    def call
      Composition.renderable_section_recordings_for(@page_recording).filter_map do |recording|
        render_section(recording)
      end
    end

    private

    def render_section(recording)
      definition = RecordingStudioPages.find_section(recording.recordable.section_type)
      return if definition.nil?

      content = definition.read_content(recording.recordable.content)
      settings = definition.read_settings(recording.recordable.settings)
      data = resolve_data(definition, recording, content, settings)
      RenderedSection.new(
        recording: recording,
        definition: definition,
        content: content,
        settings: settings,
        data: data
      )
    end

    def resolve_data(definition, recording, content, settings)
      return unless definition.data.respond_to?(:call)

      definition.data.call(recording, content, settings, @context)
    rescue StandardError
      nil
    end
  end
end
