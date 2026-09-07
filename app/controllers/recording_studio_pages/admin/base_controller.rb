# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    class BaseController < RecordingStudioPages::ApplicationController
      include RecordingStudio::UsesDefaultLayout if defined?(RecordingStudio::UsesDefaultLayout)

      before_action :authenticate_user!, raise: false
      before_action :require_admin_access!

      helper_method :page_recording, :section_recordings, :page_builder_page_path, :section_definitions,
                    :add_section_form_id, :section_action_form_id

      private

      def page_builder_page_path(recording = nil)
        recording ||= page_recording
        admin_page_path(id: recording.id)
      end

      def section_definitions
        RecordingStudioPages.sections
      end

      def add_section_form_id(definition)
        "add-section-#{page_recording.id}-#{definition.key}"
      end

      def section_action_form_id(recording, action)
        "section-#{recording.id}-#{action}"
      end

      def load_editor
        @unknown_sections = unknown_sections
        @editor_subtitle = editor_subtitle
        @rendered_sections = Renderer.call(page_recording, context: self)
      end

      def unknown_sections
        Composition.section_recordings_for(page_recording).reject do |recording|
          RecordingStudioPages.section?(recording.recordable.section_type)
        end
      end

      def editor_subtitle
        parts = []
        parts << "Public home is #{RecordingStudioPages.homepage_path}." if page_recording.recordable.homepage?
        unpublished = !page_recording.respond_to?(:currently_published?) || !page_recording.currently_published?
        parts << "Not public yet." if unpublished
        parts.join(" ").presence
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
