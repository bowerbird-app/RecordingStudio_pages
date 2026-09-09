# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    class SectionsController < BaseController
      before_action :require_admin_write_access!, only: %i[create update destroy reorder toggle duplicate]
      before_action :page_recording

      def new
        redirect_to admin_page_path(id: page_recording.id)
      end

      def create
        payload = section_payload
        result = Services::AddSection.call(
          page_recording: page_recording,
          section_type: payload[:section_type],
          content: starter_content_for(payload[:section_type]).merge(payload[:content]),
          settings: payload[:settings],
          actor: current_admin_actor
        )
        return redirect_to(admin_page_path(id: page_recording.id), alert: result.error) if result.failure?

        load_editor
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to admin_page_path(id: page_recording.id), notice: added_notice }
        end
      end

      def edit
        @section_recording = section_recording
        @definition = RecordingStudioPages.find_section(@section_recording.recordable.section_type)
        @rendered_section = Renderer.section(@section_recording, context: self)
      end

      def update
        payload = section_payload
        result = Services::ReviseSection.call(
          section_recording: section_recording,
          content: payload[:content],
          settings: payload[:settings],
          actor: current_admin_actor
        )
        if result.failure?
          return redirect_to(
            edit_admin_page_section_path(page_id: page_recording.id, id: section_recording.id),
            alert: result.error
          )
        end

        redirect_to admin_page_path(id: page_recording.id), notice: "Section saved."
      end

      def destroy
        Services::RemoveSection.call(section_recording: section_recording, actor: current_admin_actor).value!
        redirect_to admin_page_path(id: page_recording.id), notice: "Section removed."
      end

      def reorder
        position = params[:target_position].to_i
        return reject_reorder("Choose a place in the list.") if position < 1

        result = Services::MoveSection.call(
          page_recording: page_recording,
          section_recording: moving_section_recording,
          to_index: position - 1,
          actor: current_admin_actor
        )
        return reject_reorder(result.error.to_s) if result.failure?

        render json: { ok: true }
      end

      def toggle
        Services::ToggleSection.call(
          section_recording: section_recording,
          enabled: !section_recording.recordable.enabled?,
          actor: current_admin_actor
        ).value!
        redirect_to admin_page_path(id: page_recording.id)
      end

      def duplicate
        result = Services::DuplicateSection.call(
          section_recording: section_recording,
          actor: current_admin_actor
        )
        return redirect_to(admin_page_path(id: page_recording.id), alert: result.error) if result.failure?

        redirect_to admin_page_path(id: page_recording.id), notice: "Section copied."
      end

      private

      def section_recording
        @section_recording ||= find_section_recording(params[:id])
      end

      def moving_section_recording
        find_section_recording(params[:moving_recording_id])
      end

      def find_section_recording(recording_id)
        page_recording.child_recordings.find_by!(
          id: recording_id,
          recordable_type: "RecordingStudioPages::Section"
        )
      end

      def section_payload
        raw = params.fetch(:section, {}).to_unsafe_h
        {
          section_type: raw["section_type"],
          content: stringify_payload(raw["content"]),
          settings: stringify_payload(raw["settings"])
        }
      end

      def stringify_payload(raw)
        (raw || {}).to_h.stringify_keys
      end

      def starter_content_for(section_type)
        definition = RecordingStudioPages.find_section(section_type)
        return {} unless definition

        definition.starter_content
      end

      def added_notice
        "Section added."
      end
      helper_method :added_notice

      def reject_reorder(message)
        render json: { ok: false, error: message }, status: :unprocessable_content
      end
    end
  end
end
