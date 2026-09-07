# frozen_string_literal: true

RecordingStudioPublishable.configure do |config|
  config.layout = "application"
  config.management_authorizer = lambda do |recording:, actor:, **|
    actor.present? &&
      recording.present? &&
      defined?(RecordingStudioAccessible) &&
      RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :edit)
  end
  config.management_close_url_resolver = lambda do |controller:, **|
    "/recording_studio_pages/admin/pages"
  end
end
