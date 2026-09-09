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
        load_editor
      end

      def edit
        page_recording
      end

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
        result = Services::RemovePage.call(page_recording: page_recording, actor: current_admin_actor)
        return redirect_to(admin_pages_path, alert: result.error) if result.failure?

        redirect_to admin_pages_path, notice: "Page removed."
      end

      def apply_template
        result = Services::ApplyTemplate.call(
          page_recording: page_recording,
          template_key: params.require(:template_key),
          actor: current_admin_actor
        )
        return redirect_to(admin_page_path(page_recording), alert: result.error) if result.failure?

        load_editor
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to admin_page_path(page_recording), notice: "Template sections added." }
        end
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
        return recording if RecordingStudioPages.page_parent?(recording)

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

      def render_failure(result, view)
        flash.now[:alert] = result.error
        render view, status: :unprocessable_entity
      end
    end
  end
end
