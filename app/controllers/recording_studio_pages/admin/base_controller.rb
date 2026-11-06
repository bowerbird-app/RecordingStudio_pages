# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    class BaseController < RecordingStudioPages::ApplicationController
      before_action :authenticate_user!, raise: false
      before_action :require_admin_access!

      helper_method :page_recording, :section_recordings, :page_builder_page_path, :section_definitions,
                    :add_section_form_id, :section_action_form_id, :trash_page_form_id

      def default_url_options
        options = super || {}
        anchor = RecordingStudioPages::Admin.safe_anchor_url(params[:anchor_url])
        return options if anchor.blank?

        options.merge(anchor_url: anchor)
      end

      private

      def page_builder_page_path(recording = nil)
        recording ||= page_recording
        admin_page_path(id: recording.id)
      end

      def section_definitions
        RecordingStudioPages.page_sections
      end

      def add_section_form_id(definition)
        "add-section-#{page_recording.id}-#{definition.key}"
      end

      def section_action_form_id(recording, action)
        "section-#{recording.id}-#{action}"
      end

      def trash_page_form_id(recording = page_recording)
        "trash-page-#{recording.id}"
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
        return unless page_recording.recordable.homepage?

        Copy.t(
          "flashes.public_home_is",
          path: RecordingStudioPages.homepage_path
        )
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
        AccessControl.admin_authorized?(
          role: role,
          actor: current_admin_actor,
          access_recording: admin_access_recording
        )
      end

      def admin_access_recording
        return unless defined?(RecordingStudioAdmin)

        RecordingStudioAdmin.configuration.access_recording_resolver&.call(admin_context)
      end

      def admin_context
        RecordingStudioAdmin::Context.new(controller: self) if defined?(RecordingStudioAdmin::Context)
      end

      def current_admin_actor
        return current_user if respond_to?(:current_user)

        Current.actor if defined?(Current)
      end

      def page_recording
        @page_recording ||= AccessControl.find_page_recording!(
          id: params[:page_id] || params[:id],
          actor: current_admin_actor
        )
      end

      def section_recordings
        Composition.section_recordings_for(page_recording)
      end
    end
  end
end
