# frozen_string_literal: true

RecordingStudioAccessible.configure do |config|
  config.access_actor_types = [ "User" ]
  config.access_actor_types += ["RecordingStudioApi::ApiClient"] if defined?(RecordingStudioApi)

  # Admin 2.15+ :site screens (Pages) require this recording to equal
  # the access recording. The dummy Admin root is the recordable named Admin.
  config.admin_root_resolver = lambda do
    admin_root = AdminRoot.find_by(name: "Admin")
    next unless admin_root

    RecordingStudio::Recording.where(trashed_at: nil, parent_recording_id: nil).find_by(recordable: admin_root)
  end
end
