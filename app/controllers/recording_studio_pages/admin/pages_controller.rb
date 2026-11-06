# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    class PagesController < BaseController
      before_action :require_admin_write_access!, only: %i[create update destroy]

      def index
        @page_recordings = page_scope
      end

      def new; end

      def create
        result = Services::CreatePage.call(
          parent_recording: create_parent_recording,
          title: page_params[:title],
          homepage: checked?(page_params[:homepage]),
          actor: current_admin_actor
        )
        return render_failure(result, :new) if result.failure?

        redirect_to admin_page_path(result.value),
                    notice: Copy.t("flashes.page_created")
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
          homepage: checked?(page_params[:homepage]),
          actor: current_admin_actor
        )
        return render_failure(result, :edit) if result.failure?

        redirect_to admin_page_path(result.value),
                    notice: Copy.t("flashes.page_saved")
      end

      def destroy
        result = Services::RemovePage.call(page_recording: page_recording, actor: current_admin_actor)
        return redirect_to(admin_pages_path, alert: Copy.user_message(result.error)) if result.failure?

        redirect_to admin_pages_path,
                    notice: Copy.t("flashes.in_the_trash")
      end

      private

      def page_scope
        AccessControl.page_recordings_for(actor: current_admin_actor)
                     .includes(:recordable)
                     .order(updated_at: :desc)
      end

      def page_params
        params.fetch(:page, {}).permit(:title, :homepage)
      end

      def checked?(value)
        ActiveModel::Type::Boolean.new.cast(value) == true
      end

      def create_parent_recording
        AccessControl.writable_page_parent(switched_content_root, actor: current_admin_actor) ||
          AccessControl.first_writable_workspace_root(actor: current_admin_actor)
      end

      def switched_content_root
        return unless respond_to?(:current_root_recording, true)

        recording = current_root_recording
        return if recording.blank?

        recording
      rescue StandardError
        nil
      end

      def render_failure(result, view)
        flash.now[:alert] = Copy.user_message(result.error)
        render view, status: :unprocessable_entity
      end
    end
  end
end
