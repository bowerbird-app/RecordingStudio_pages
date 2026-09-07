# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    class BaseController < RecordingStudioPages::ApplicationController
      include RecordingStudio::UsesDefaultLayout if defined?(RecordingStudio::UsesDefaultLayout)

      before_action :authenticate_user!, raise: false
      before_action :require_admin_access!

      helper_method :page_recording, :section_recordings, :page_builder_page_path, :page_builder_new_section_path

      private

      def page_builder_page_path(recording = nil)
        recording ||= page_recording
        admin_page_path(id: recording.id)
      end

      def page_builder_new_section_path(recording = nil, section_type: nil)
        recording ||= page_recording
        options = { page_id: recording.id }
        options[:section_type] = section_type if section_type.present?
        new_admin_page_section_path(options)
      end

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
    end
  end
end
