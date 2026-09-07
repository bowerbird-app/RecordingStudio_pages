# frozen_string_literal: true

module RecordingStudioPages
  module Composition
    module_function

    def section_recordings_for(page_recording)
      scope = ordered_children(page_recording)
      scope = scope.where(trashed_at: nil) if scope.klass.column_names.include?("trashed_at")
      scope.select { |recording| recording.recordable_type == "RecordingStudioPages::Section" }
    end

    def renderable_section_recordings_for(page_recording)
      section_recordings_for(page_recording).select do |recording|
        recordable = recording.recordable
        next false unless recordable.respond_to?(:enabled?)
        next false unless recordable.enabled?
        next false unless RecordingStudioPages.section?(recordable.section_type)

        true
      end
    end

    def homepage_recording(root_recording: nil)
      scope = RecordingStudio::Recording.where(
        recordable_type: "RecordingStudioPages::Page",
        trashed_at: nil
      )
      scope = scope.where(root_recording_id: root_recording.id) if root_recording
      candidates = scope.includes(:recordable).select { |recording| recording.recordable&.homepage? }
      published, others = candidates.partition do |recording|
        recording.respond_to?(:currently_published?) && recording.currently_published?
      end
      published.first || others.first
    end

    def ordered_children(page_recording)
      if page_recording.respond_to?(:recording_studio_orderable_children)
        page_recording.recording_studio_orderable_children
      else
        page_recording.child_recordings
      end
    end
  end
end
