# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    class PagesController < BaseController
      before_action :require_admin_write_access!, only: %i[create update destroy apply_template]

      def index
        @page_recordings = page_scope
      end

      def new
        @templates = RecordingStudioPages.templates
      end

      def create
        result = Services::CreatePage.call(
          parent_recording: create_parent_recording,
          title: page_params[:title],
          homepage: boolean_param(page_params[:homepage]),
          template_key: page_params[:template_key].presence,
          actor: current_admin_actor
        )
        return render_failure(result, :new) if result.failure?

        if page_params[:template_key].present?
          Services::ApplyTemplate.call(
            page_recording: result.value,
            template_key: page_params[:template_key],
            actor: current_admin_actor
          ).value!
        end

        redirect_to admin_page_path(result.value), notice: "Page created."
      end

      def show
        @rendered_sections = Renderer.call(page_recording, context: self)
        @unknown_sections = unknown_sections
        @editor_subtitle = editor_subtitle
      end

      def edit; end

      def update
        result = Services::RevisePage.call(
          page_recording: page_recording,
          title: page_params[:title],
          homepage: boolean_param(page_params[:homepage]),
          actor: current_admin_actor
        )
        return render_failure(result, :edit) if result.failure?

        redirect_to admin_page_path(result.value), notice: "Page saved."
      end

      def destroy
        if page_recording.respond_to?(:trash!)
          page_recording.trash!(actor: current_admin_actor)
        else
          page_recording.update!(trashed_at: Time.current)
        end
        redirect_to admin_pages_path, notice: "Page removed."
      end

      def apply_template
        result = Services::ApplyTemplate.call(
          page_recording: page_recording,
          template_key: params.require(:template_key),
          actor: current_admin_actor
        )
        return redirect_to(admin_page_path(page_recording), alert: result.error) if result.failure?

        redirect_to admin_page_path(page_recording), notice: "Template sections added."
      end

      private

      def page_scope
        RecordingStudio::Recording.where(recordable_type: "RecordingStudioPages::Page", trashed_at: nil)
                                  .includes(:recordable)
                                  .order(updated_at: :desc)
      end

      def page_params
        params.fetch(:page, {}).permit(:title, :homepage, :template_key)
      end

      def boolean_param(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end

      def create_parent_recording
        switched_content_root || first_workspace_root
      end

      def switched_content_root
        return unless respond_to?(:current_root_recording, true)

        recording = current_root_recording
        return if recording.blank?
        return recording if %w[Workspace Folder].include?(recording.recordable_type)

        nil
      rescue StandardError
        nil
      end

      def first_workspace_root
        RecordingStudio::Recording.find_by(
          parent_recording_id: nil,
          trashed_at: nil,
          recordable_type: "Workspace"
        )
      end

      def unknown_sections
        Composition.section_recordings_for(page_recording).reject do |recording|
          RecordingStudioPages.section?(recording.recordable.section_type)
        end
      end

      def editor_subtitle
        parts = []
        parts << "This is the public home page." if page_recording.recordable.homepage?
        unpublished = !page_recording.respond_to?(:currently_published?) || !page_recording.currently_published?
        parts << "Staff preview. This page is not public yet." if unpublished
        parts.join(" ").presence
      end

      def render_failure(result, view)
        flash.now[:alert] = result.error
        render view, status: :unprocessable_entity
      end
    end
  end
end
