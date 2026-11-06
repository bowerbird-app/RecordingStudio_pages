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
  config.authorize_write = lambda { |actor:, recording:, recordable:, parent_recording:, root_recording:, **|
    next false unless actor && defined?(RecordingStudioAccessible)

    access_row = recordable.is_a?(RecordingStudio::Access) ||
                 recording&.recordable.is_a?(RecordingStudio::Access)
    next true if access_row && RecordingStudioAccessible::AccessCreationContext.allowed?

    target = recording || parent_recording || root_recording
    next false unless target

    role = access_row ? :admin : :edit
    next true if RecordingStudioAccessible.authorized?(actor: actor, recording: target, role: role)

    # People is a shared root. Accessible rejects grants on it. Users writes the
    # Profile child first, then bootstraps owner access on that child.
    defined?(RecordingStudioUser::Profile) &&
      recordable.is_a?(RecordingStudioUser::Profile) &&
      RecordingStudio.shared_root_tree?(target)
  }
  config.event_notifications_enabled = true
  config.idempotency_mode = :return_existing
  config.recordable_dup_strategy = :dup
end
