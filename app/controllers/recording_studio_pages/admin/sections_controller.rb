# frozen_string_literal: true

module RecordingStudioPages
  module Admin
    class SectionsController < BaseController
      before_action :require_admin_write_access!, only: %i[create update destroy move toggle duplicate]
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
        redirect_to admin_page_path(id: page_recording.id)
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
        @section_recording ||= page_recording.child_recordings.find_by!(
          id: params[:id],
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
    end
  end
end
