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
  config.require_recordable_declarations = true
  config.app_name = "Page Builder" if config.respond_to?(:app_name=)
  config.actor = -> { Current.actor }
  config.authorize_write = lambda { |actor:, recording:, parent_recording:, root_recording:, **|
    next false unless actor && defined?(RecordingStudioAccessible)
    next true if RecordingStudioAccessible::AccessCreationContext.allowed?

    target = recording || parent_recording || root_recording
    next false unless target
    next true if RecordingStudioAccessible.authorized?(actor: actor, recording: target, role: :edit)

    root = root_recording || (target.respond_to?(:root_recording) && target.root_recording) || target
    RecordingStudioAccessible.access_recordings_for(root).none?
  }
  config.event_notifications_enabled = true
  config.idempotency_mode = :return_existing
  config.recordable_dup_strategy = :dup
end
