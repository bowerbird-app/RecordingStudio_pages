# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    class BaseController < RecordingStudioPages::ApplicationController
      include RecordingStudio::UsesDefaultLayout if defined?(RecordingStudio::UsesDefaultLayout)

      before_action :authenticate_user!, raise: false

      helper_method :page_recording, :section_recordings, :page_builder_page_path, :section_definitions,
                    :add_section_form_id, :section_action_form_id, :pages_admin_screen_path

      private

      def page_builder_page_path(recording = nil)
        recording ||= page_recording
        admin_page_path(id: recording.id)
      end

      def pages_admin_screen_path
        RecordingStudioPages::Admin.screen_path
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

      def authorize_pages_view!
        authorize_pages_resource!(:open)
      end

      def authorize_pages_write!
        authorize_pages_resource!(:edit)
      end

      def authorize_pages_resource!(action)
        unless defined?(RecordingStudioAdmin)
          head :forbidden
          return
        end

        RecordingStudioAdmin.authorize_resource!(
          key: RESOURCE_KEY,
          action: action,
          context: pages_admin_context,
          record: pages_admin_record
        )
      rescue RecordingStudioAdmin::AuthorizationFailed, RecordingStudioAdmin::DefinitionNotFound
        head :forbidden
      end

      def pages_admin_context
        RecordingStudioAdmin::Context.new(
          params: params.to_unsafe_h,
          current_actor: current_admin_actor,
          controller: self,
          routes: (main_app if respond_to?(:main_app)),
          view_context: (view_context if respond_to?(:view_context, true))
        )
      end

      def pages_admin_record
        return if params[:id].blank? && params[:page_id].blank?

        page_recording
      rescue ActiveRecord::RecordNotFound
        nil
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
