# frozen_string_literal: true

class AddIndexesToPublishable < ActiveRecord::Migration[8.1]
  def up
    table = :recording_studio_publishable_publishables
    return if index_name_exists?(table, "index_publishables_on_status_and_publish_times")

    add_index table, %i[status publish_at unpublish_at], name: "index_publishables_on_status_and_publish_times"
  end

  def down
    table = :recording_studio_publishable_publishables
    return unless index_name_exists?(table, "index_publishables_on_status_and_publish_times")

    remove_index table, name: "index_publishables_on_status_and_publish_times"
  end
end
