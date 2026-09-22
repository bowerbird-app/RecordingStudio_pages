# frozen_string_literal: true

# Dummy defaults the current root to a Workspace. RS Admin 403s (blank body)
# unless that root is the Admin root. Switch before Admin authorizes, and only
# when Accessible already grants the Admin gate role. Do not bypass the gate.
module SwitchToAdminRoot
  extend ActiveSupport::Concern

  included do
    before_action :switch_to_admin_root_when_needed
  end

  private

  def switch_to_admin_root_when_needed
    return unless defined?(RecordingStudio::RootSwitchable::Services::SwitchRoot)
    return unless respond_to?(:current_root_recording, true)

    admin_recording = dummy_admin_root_recording
    return if admin_recording.blank?

    current = current_root_recording
    return if current && RecordingStudio::RootSwitchable::RootId.same?(current.id, admin_recording.id)

    actor = dummy_admin_switch_actor
    return if actor.blank?
    return unless dummy_admin_root_accessible?(actor, admin_recording)

    RecordingStudio::RootSwitchable::Services::SwitchRoot.call(
      controller: self,
      actor: actor,
      device_key: current_root_device_key,
      root_recording_id: admin_recording.id,
      scope_key: current_root_scope_key.presence || "all_workspaces"
    )
  end

  def dummy_admin_switch_actor
    return Current.actor if defined?(Current) && Current.respond_to?(:actor) && Current.actor.present?
    return current_user if respond_to?(:current_user, true)

    nil
  end

  def dummy_admin_root_recording
    admin_root = AdminRoot.find_by(name: "Admin")
    return unless admin_root

    RecordingStudio::Recording.find_by(recordable: admin_root, trashed_at: nil)
  end

  def dummy_admin_root_accessible?(actor, admin_recording)
    return false unless defined?(RecordingStudioAccessible)

    role = if defined?(RecordingStudioAdmin)
             RecordingStudioAdmin.configuration.required_access_role
           else
             :view
           end

    RecordingStudioAccessible.authorized?(
      actor: actor,
      recording: admin_recording,
      role: role
    )
  end
end
