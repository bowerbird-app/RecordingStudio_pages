# frozen_string_literal: true

module RecordingStudioPages
  module AccessControl
    PAGE_TYPE = "RecordingStudioPages::Page"
    WORKSPACE_TYPE = "Workspace"

    module_function

    def accessible_loaded?
      defined?(RecordingStudioAccessible)
    end

    def admin_loaded?
      defined?(RecordingStudioAdmin)
    end

    def admin_authorized?(role:, actor:, access_recording:, accessible: accessible_loaded?, admin: admin_loaded?)
      return false unless accessible && admin
      return false unless actor && access_recording

      RecordingStudioAccessible.authorized?(
        actor: actor,
        recording: access_recording,
        role: role
      )
    end

    def authorized?(actor:, recording:, role:, accessible: accessible_loaded?)
      return false unless accessible
      return false unless actor && recording

      RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: role)
    end

    def page_recordings_for(actor:, accessible: accessible_loaded?)
      scope = page_recordings
      return scope.none unless accessible && actor

      ids = scope.filter_map do |recording|
        recording.id if authorized?(actor: actor, recording: recording, role: :view, accessible: accessible)
      end
      scope.where(id: ids)
    end

    def find_page_recording!(id:, actor:, accessible: accessible_loaded?)
      recording = page_recordings.find_by!(id: id)
      unless authorized?(actor: actor, recording: recording, role: :view, accessible: accessible)
        raise ActiveRecord::RecordNotFound
      end

      recording
    end

    def first_writable_workspace_root(actor:, accessible: accessible_loaded?)
      return unless accessible && actor

      workspace_roots.find do |recording|
        authorized?(actor: actor, recording: recording, role: :edit, accessible: accessible)
      end
    end

    def writable_page_parent(recording, actor:, accessible: accessible_loaded?)
      return unless RecordingStudioPages.page_parent?(recording)
      return unless authorized?(actor: actor, recording: recording, role: :edit, accessible: accessible)

      recording
    end

    def page_recordings
      RecordingStudio::Recording.where(recordable_type: PAGE_TYPE, trashed_at: nil)
    end

    def workspace_roots
      RecordingStudio::Recording.where(
        parent_recording_id: nil,
        trashed_at: nil,
        recordable_type: WORKSPACE_TYPE
      )
    end
  end
end
