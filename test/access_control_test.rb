# frozen_string_literal: true

require "test_helper"

class AccessControlTest < Minitest::Test
  Actor = Struct.new(:id)
  Recording = Struct.new(:id)

  def test_admin_gate_denies_when_accessible_is_missing
    refute RecordingStudioPages::AccessControl.admin_authorized?(
      role: :view,
      actor: Actor.new(1),
      access_recording: Recording.new(1),
      accessible: false,
      admin: true
    )
  end

  def test_admin_gate_denies_when_admin_is_missing
    refute RecordingStudioPages::AccessControl.admin_authorized?(
      role: :view,
      actor: Actor.new(1),
      access_recording: Recording.new(1),
      accessible: true,
      admin: false
    )
  end

  def test_admin_gate_denies_without_actor_or_access_recording
    refute RecordingStudioPages::AccessControl.admin_authorized?(
      role: :view,
      actor: nil,
      access_recording: Recording.new(1),
      accessible: true,
      admin: true
    )
    refute RecordingStudioPages::AccessControl.admin_authorized?(
      role: :edit,
      actor: Actor.new(1),
      access_recording: nil,
      accessible: true,
      admin: true
    )
  end

  def test_authorized_denies_when_accessible_is_missing
    refute RecordingStudioPages::AccessControl.authorized?(
      actor: Actor.new(1),
      recording: Recording.new(1),
      role: :view,
      accessible: false
    )
  end

  def test_admin_base_controller_fails_closed_when_accessible_is_missing
    source = File.read(
      File.expand_path("../app/controllers/recording_studio_pages/admin/base_controller.rb", __dir__)
    )

    refute_includes source, "return true unless defined?(RecordingStudioAccessible)"
    refute_includes source, "return true unless defined?(RecordingStudioAdmin)"
    assert_includes source, "AccessControl.admin_authorized?"
    assert_includes source, "AccessControl.find_page_recording!"
  end

  def test_admin_pages_controller_scopes_lists_and_create_parent
    source = File.read(
      File.expand_path("../app/controllers/recording_studio_pages/admin/pages_controller.rb", __dir__)
    )

    assert_includes source, "AccessControl.page_recordings_for"
    assert_includes source, "AccessControl.first_writable_workspace_root"
    refute_includes source, "recordable_type: \"Workspace\""
  end

  def test_writable_page_parent_denies_when_accessible_is_missing
    recording = Object.new
    def recording.recordable_type
      "Workspace"
    end

    refute RecordingStudioPages::AccessControl.writable_page_parent(
      recording,
      actor: Actor.new(1),
      accessible: false
    )
  end
end
