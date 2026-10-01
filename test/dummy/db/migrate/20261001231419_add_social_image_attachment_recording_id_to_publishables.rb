# frozen_string_literal: true

class AddSocialImageAttachmentRecordingIdToPublishables < ActiveRecord::Migration[8.1]
  def up
    table = :recording_studio_publishable_publishables
    unless column_exists?(table, :social_image_attachment_recording_id)
      add_column table, :social_image_attachment_recording_id, :uuid
    end

    unless index_name_exists?(table, "index_rs_publishables_on_social_image_attachment_recording_id")
      add_index table,
                :social_image_attachment_recording_id,
                name: "index_rs_publishables_on_social_image_attachment_recording_id"
    end

    return if foreign_key_exists?(table, :recording_studio_recordings, column: :social_image_attachment_recording_id)

    add_foreign_key table,
                    :recording_studio_recordings,
                    column: :social_image_attachment_recording_id,
                    name: "fk_rs_publishables_social_image_attachment_recording"
  end

  def down
    table = :recording_studio_publishable_publishables
    if foreign_key_exists?(table, name: "fk_rs_publishables_social_image_attachment_recording")
      remove_foreign_key table, name: "fk_rs_publishables_social_image_attachment_recording"
    end
  end
end
