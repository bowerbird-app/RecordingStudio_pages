# frozen_string_literal: true

RecordingStudioTrashable.configure do |config|
  config.use_recording_studio_accessible = true
  config.allow_unconfigured_authorization = false
  config.authorization_roles = {
    trash: :edit,
    restore: :edit,
    purge: :admin,
    settings: :admin,
    trash_bin: :edit
  }
  config.default_purge_after_days = nil
  config.allow_user_retention_settings = false
end
