# frozen_string_literal: true

class AddRecordingStudioOrderablePosition < ActiveRecord::Migration[8.1]
  def change
    return if column_exists?(:recording_studio_recordings, :recording_studio_orderable_position)

    add_column :recording_studio_recordings, :recording_studio_orderable_position, :integer
    add_index :recording_studio_recordings,
              %i[parent_recording_id recording_studio_orderable_position],
              name: "idx_rs_recordings_orderable_sibling_position"
  end
end
