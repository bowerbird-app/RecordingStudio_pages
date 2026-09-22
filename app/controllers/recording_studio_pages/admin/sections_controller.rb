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
        parent = parent_for_new_section(payload[:parent_section_id])
        result = Services::AddSection.call(
          parent_recording: parent,
          section_type: payload[:section_type],
          content: starter_content_for(payload[:section_type]).merge(payload[:content]),
          settings: payload[:settings],
          actor: current_admin_actor
        )
        return redirect_to(section_home_path(parent), alert: result.error) if result.failure?

        if parent.recordable_type == "RecordingStudioPages::Section"
          redirect_to section_home_path(parent), notice: added_notice_for(payload[:section_type])
        else
          load_editor
          respond_to do |format|
            format.turbo_stream { flash.now[:notice] = added_notice }
            format.html { redirect_to admin_page_path(id: page_recording.id), notice: added_notice }
          end
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

        redirect_to edit_admin_page_section_path(page_id: page_recording.id, id: section_recording.id),
                    notice: "Updated."
      end

      def destroy
        recording = section_recording
        parent = recording.parent_recording
        Services::RemoveSection.call(section_recording: recording, actor: current_admin_actor).value!
        redirect_to section_home_path(parent), notice: "Section removed."
      end

      def reorder
        position = params[:target_position].to_i
        return reject_reorder("Choose a place in the list.") if position < 1

        moving = moving_section_recording
        result = Services::MoveSection.call(
          page_recording: moving.parent_recording,
          section_recording: moving,
          to_index: position - 1,
          actor: current_admin_actor
        )
        return reject_reorder(result.error.to_s) if result.failure?

        render json: { ok: true }
      end

      def toggle
        recording = section_recording
        parent = recording.parent_recording
        Services::ToggleSection.call(
          section_recording: recording,
          enabled: !recording.recordable.enabled?,
          actor: current_admin_actor
        ).value!
        redirect_to section_home_path(parent)
      end

      def duplicate
        recording = section_recording
        parent = recording.parent_recording
        result = Services::DuplicateSection.call(
          section_recording: recording,
          actor: current_admin_actor
        )
        return redirect_to(section_home_path(parent), alert: result.error) if result.failure?

        redirect_to section_home_path(parent), notice: "Section copied."
      end

      private

      def section_recording
        @section_recording ||= find_section_recording(params[:id])
      end

      def moving_section_recording
        find_section_recording(params[:moving_recording_id])
      end

      def find_section_recording(recording_id)
        recording = RecordingStudio::Recording.find_by!(
          id: recording_id,
          recordable_type: "RecordingStudioPages::Section",
          trashed_at: nil
        )
        raise ActiveRecord::RecordNotFound unless belongs_to_page?(recording)

        recording
      end

      def belongs_to_page?(recording)
        current = recording
        seen = {}
        while current && !seen[current.id]
          return true if current.id == page_recording.id || current.parent_recording_id == page_recording.id

          seen[current.id] = true
          current = current.parent_recording
        end
        false
      end

      def parent_for_new_section(parent_section_id)
        return page_recording if parent_section_id.blank?

        find_section_recording(parent_section_id)
      end

      def section_home_path(parent)
        if parent&.recordable_type == "RecordingStudioPages::Section"
          edit_admin_page_section_path(page_id: page_recording.id, id: parent.id)
        else
          admin_page_path(id: page_recording.id)
        end
      end

      def section_payload
        raw = params.fetch(:section, {}).to_unsafe_h
        {
          section_type: raw["section_type"],
          parent_section_id: raw["parent_section_id"],
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

      def added_notice_for(section_type)
        name = RecordingStudioPages.find_section(section_type)&.name
        name.present? ? "#{name} added." : added_notice
      end

      def reject_reorder(message)
        render json: { ok: false, error: message }, status: :unprocessable_content
      end
    end
  end
end
