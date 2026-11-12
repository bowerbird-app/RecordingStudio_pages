# frozen_string_literal: true

RecordingStudio.configure do |config|
  config.recordable_types = [
    "Workspace",
    "Folder",
    "AdminRoot",
    "RecordingStudioUser::People",
    "RecordingStudioUser::Profile",
    "RecordingStudioPages::Page",
    "RecordingStudioPages::Section",
    "RecordingStudioPublishable::Publishable",
    "RecordingStudioAttachable::Attachment"
  ]
  config.recordable_types += [
    "RecordingStudioApi::ApiClient",
    "RecordingStudioApi::ApiCredential",
    "RecordingStudioApi::ApiAccessToken",
    "RecordingStudioApi::AdminApi"
  ] if defined?(RecordingStudioApi)
  config.require_recordable_declarations = true
  config.app_name = "Page Builder" if config.respond_to?(:app_name=)
  config.actor = -> { Current.actor }
  config.authorize_write = lambda { |actor:, recording:, recordable:, parent_recording:, root_recording:, **|
    next false unless actor && defined?(RecordingStudioAccessible)

    access_row = recordable.is_a?(RecordingStudio::Access) ||
                 recording&.recordable.is_a?(RecordingStudio::Access)
    next true if access_row && RecordingStudioAccessible::AccessCreationContext.allowed?
    next true if defined?(RecordingStudioApi::ApiClient) && [RecordingStudioApi::ApiClient, RecordingStudioApi::ApiCredential, RecordingStudioApi::ApiAccessToken, RecordingStudioApi::AdminApi].any? { recordable.is_a?(_1) } && RecordingStudioAccessible::AccessCreationContext.allowed?

    target = recording || parent_recording || root_recording
    next false unless target

    role = access_row ? :admin : :edit
    RecordingStudioAccessible.authorized?(actor: actor, recording: target, role: role)
  }
  config.event_notifications_enabled = true
  config.idempotency_mode = :return_existing
  config.recordable_dup_strategy = :dup
end
