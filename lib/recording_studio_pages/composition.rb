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

    def page_recordings
      RecordingStudio::Recording.where(
        recordable_type: "RecordingStudioPages::Page",
        trashed_at: nil
      )
    end

    def published_pages_count
      live_ids = currently_live_publishable_ids
      return 0 if live_ids.blank?

      RecordingStudio::Recording.where(
        recordable_type: "RecordingStudioPublishable::Publishable",
        recordable_id: live_ids,
        trashed_at: nil,
        parent_recording_id: page_recordings.select(:id)
      ).distinct.count(:parent_recording_id)
    end

    def draft_pages_count
      [page_recordings.count - published_pages_count, 0].max
    end

    def currently_live_publishable_ids
      return [] unless defined?(RecordingStudioPublishable::Publishable)

      RecordingStudioPublishable::Publishable.currently_published.select(:id)
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
