# frozen_string_literal: true

module RecordingStudioPages
  module Composition
    module_function

    STATUS_DRAFT = "Draft"
    STATUS_SCHEDULED = "Scheduled"
    STATUS_PUBLISHED = "Published"
    STATUS_OPTIONS = [STATUS_DRAFT, STATUS_SCHEDULED, STATUS_PUBLISHED].freeze

    HOMEPAGE_HOME = "Home"
    HOMEPAGE_OTHER = "Other pages"
    HOMEPAGE_OPTIONS = [HOMEPAGE_HOME, HOMEPAGE_OTHER].freeze

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
      published, others = candidates.partition { |recording| live_page?(recording) }
      published.first || others.first
    end

    def page_recordings
      RecordingStudio::Recording.where(
        recordable_type: "RecordingStudioPages::Page",
        trashed_at: nil
      )
    end

    def published_pages_count
      live_page_recording_ids.except(:select).distinct.count(:parent_recording_id)
    end

    def draft_pages_count
      filter_page_recordings_by_status(page_recordings, STATUS_DRAFT).count
    end

    def live_page_recording_ids
      page_recording_ids_for_publishables(currently_live_publishable_ids)
    end

    def scheduled_page_recording_ids
      page_recording_ids_for_publishables(currently_scheduled_publishable_ids)
    end

    def filter_page_recordings_by_status(relation, value)
      case value.to_s
      when STATUS_PUBLISHED
        relation.where(id: live_page_recording_ids)
      when STATUS_SCHEDULED
        relation.where(id: scheduled_page_recording_ids)
      when STATUS_DRAFT
        relation.where.not(id: live_page_recording_ids).where.not(id: scheduled_page_recording_ids)
      else
        relation
      end
    end

    def filter_page_recordings_by_homepage(relation, value)
      homepage_ids = RecordingStudioPages::Page.where(homepage: true).select(:id)

      case value.to_s
      when HOMEPAGE_HOME
        relation.where(recordable_id: homepage_ids)
      when HOMEPAGE_OTHER
        relation.where.not(recordable_id: homepage_ids)
      else
        relation
      end
    end

    def page_status(recording)
      return STATUS_PUBLISHED if live_page?(recording)
      return STATUS_SCHEDULED if scheduled_page?(recording)

      STATUS_DRAFT
    end

    def live_page?(recording)
      recording.respond_to?(:currently_published?) && recording.currently_published?
    end

    def scheduled_page?(recording)
      recording.respond_to?(:scheduled_for_future?) && recording.scheduled_for_future?
    end

    def currently_live_publishable_ids
      return [] unless defined?(RecordingStudioPublishable::Publishable)

      RecordingStudioPublishable::Publishable.currently_published.select(:id)
    end

    def currently_scheduled_publishable_ids
      return [] unless defined?(RecordingStudioPublishable::Publishable)

      RecordingStudioPublishable::Publishable.scheduled.select(:id)
    end

    def page_recording_ids_for_publishables(publishable_ids)
      return RecordingStudio::Recording.none.select(:parent_recording_id) if publishable_ids.blank?

      RecordingStudio::Recording.where(
        recordable_type: "RecordingStudioPublishable::Publishable",
        recordable_id: publishable_ids,
        trashed_at: nil,
        parent_recording_id: page_recordings.select(:id)
      ).distinct.select(:parent_recording_id)
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
