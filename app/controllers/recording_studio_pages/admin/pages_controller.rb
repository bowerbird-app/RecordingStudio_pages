# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    class PagesController < BaseController
      before_action :authorize_pages_view!, only: %i[index show new edit]
      before_action :authorize_pages_write!, only: %i[create update destroy apply_template]

      def index
        redirect_to pages_admin_screen_path
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
        return redirect_to(pages_admin_screen_path, alert: result.error) if result.failure?

        redirect_to pages_admin_screen_path, notice: "Page removed."
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

      def page_params
        params.fetch(:page, {}).permit(:title, :homepage, :template_key)
      end

      def boolean_param(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end

      def create_parent_recording
        switched_content_root || writable_workspace_root || first_workspace_root
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

      def writable_workspace_root
        return unless current_admin_actor
        return unless defined?(RecordingStudioAccessible)

        workspace_roots.find do |recording|
          RecordingStudioAccessible.authorized?(
            actor: current_admin_actor,
            recording: recording,
            role: :edit
          )
        end
      end

      def first_workspace_root
        workspace_roots.first
      end

      def workspace_roots
        RecordingStudio::Recording.where(
          parent_recording_id: nil,
          trashed_at: nil,
          recordable_type: "Workspace"
        ).order(:created_at, :id)
      end

      def render_failure(result, view)
        flash.now[:alert] = result.error
        render view, status: :unprocessable_entity
      end
    end
  end
end
