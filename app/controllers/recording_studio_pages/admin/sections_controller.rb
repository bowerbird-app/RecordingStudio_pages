# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    class SectionsController < BaseController
      def new
        @definition = RecordingStudioPages.section(params[:section_type]) if params[:section_type].present?
        @definitions = RecordingStudioPages.sections
      end

      def create
        payload = section_payload
        result = Services::AddSection.call(
          page_recording: page_recording,
          section_type: payload[:section_type],
          content: payload[:content],
          settings: payload[:settings],
          actor: current_admin_actor
        )
        if result.failure?
          return redirect_to(
            new_admin_page_section_path(page_recording, section_type: payload[:section_type]),
            alert: result.error
          )
        end

        redirect_to admin_page_path(page_recording), notice: "Section added."
      end

      def edit
        @section_recording = section_recording
        @definition = RecordingStudioPages.find_section(@section_recording.recordable.section_type)
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
            edit_admin_page_section_path(page_recording, section_recording),
            alert: result.error
          )
        end

        redirect_to admin_page_path(page_recording), notice: "Section saved."
      end

      def destroy
        Services::RemoveSection.call(section_recording: section_recording, actor: current_admin_actor).value!
        redirect_to admin_page_path(page_recording), notice: "Section removed."
      end

      def move
        ids = Composition.section_recordings_for(page_recording).map { |recording| recording.id.to_s }
        current_index = ids.index(section_recording.id.to_s)
        direction = params[:direction].to_s
        swap_index = direction == "up" ? current_index - 1 : current_index + 1
        if current_index && swap_index.between?(0, ids.length - 1)
          ids[current_index], ids[swap_index] = ids[swap_index], ids[current_index]
          Services::ReorderSections.call(
            page_recording: page_recording,
            ordered_recording_ids: ids,
            actor: current_admin_actor
          ).value!
        end
        redirect_to admin_page_path(page_recording)
      end

      def toggle
        Services::ToggleSection.call(
          section_recording: section_recording,
          enabled: !section_recording.recordable.enabled?,
          actor: current_admin_actor
        ).value!
        redirect_to admin_page_path(page_recording)
      end

      private

      def section_recording
        @section_recording ||= page_recording.child_recordings.find_by!(
          id: params[:id],
          recordable_type: "RecordingStudioPages::Section"
        )
      end

      def section_payload
        raw = params.fetch(:section, {}).to_unsafe_h
        {
          section_type: raw["section_type"],
          content: raw["content"] || {},
          settings: raw["settings"] || {}
        }
      end
    end
  end
end
