# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    class BaseController < RecordingStudioPages::ApplicationController
      include RecordingStudio::UsesDefaultLayout if defined?(RecordingStudio::UsesDefaultLayout)

      before_action :authenticate_user!, raise: false
      before_action :require_admin_access!
      before_action :require_admin_write_access!, only: %i[create update destroy apply_template move toggle]

      helper_method :page_recording, :section_recordings

      private

      def require_admin_access!
        return if admin_authorized?(:view)

        head :forbidden
      end

      def require_admin_write_access!
        return if admin_authorized?(:edit)

        head :forbidden
      end

      def admin_authorized?(role)
        return true unless defined?(RecordingStudioAccessible)
        return true unless defined?(RecordingStudioAdmin)

        access_recording = RecordingStudioAdmin.configuration.access_recording_resolver&.call(admin_context)
        return false unless access_recording

        RecordingStudioAccessible.authorized?(
          actor: current_admin_actor,
          recording: access_recording,
          role: role
        )
      end

      def admin_context
        RecordingStudioAdmin::Context.new(controller: self) if defined?(RecordingStudioAdmin::Context)
      end

      def current_admin_actor
        return current_user if respond_to?(:current_user)

        Current.actor if defined?(Current)
      end

      def page_recording
        @page_recording ||= RecordingStudio::Recording.find_by!(
          id: params[:page_id] || params[:id],
          recordable_type: "RecordingStudioPages::Page",
          trashed_at: nil
        )
      end

      def section_recordings
        Composition.section_recordings_for(page_recording)
      end

      def current_root_recording
        return page_recording.root_recording || page_recording if params[:id].present? || params[:page_id].present?
        return unless respond_to?(:current_workspace, true)

        workspace = send(:current_workspace) if respond_to?(:current_workspace, true)
        RecordingStudio.root_recording_for(workspace) if workspace
      rescue StandardError
        nil
      end
    end
  end
end
