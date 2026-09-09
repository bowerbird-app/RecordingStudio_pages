# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"
require "devise/test/integration_helpers"

module PageBuilderTestHelper
  TEST_PASSWORD = "Password123!"

  def create_actor!(email)
    User.find_or_create_by!(email: email) do |user|
      user.password = TEST_PASSWORD
      user.password_confirmation = TEST_PASSWORD
    end
  end

  def create_workspace_root!(name)
    workspace = Workspace.create!(name: name)
    RecordingStudio.root_recording_for(workspace)
  end

  def create_admin_root!(name: "Admin")
    admin_root = AdminRoot.find_or_create_by!(name: name)
    RecordingStudio.root_recording_for(admin_root)
  end

  def grant_admin!(recording, actor)
    return if RecordingStudioAccessible.role_for(actor: actor, recording: recording) == :admin

    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
    return result.value if result.success?

    manager = User.where.not(id: actor.id).first
    if manager
      result = RecordingStudioAccessible.grant_access(
        recording: recording,
        actor: actor,
        role: :admin,
        manager_actor: manager
      )
    end

    raise result.error if result.failure?

    result.value
  end

  def create_page!(parent_recording:, title:, homepage: false, actor:)
    RecordingStudioPages::Services::CreatePage.call(
      parent_recording: parent_recording,
      title: title,
      homepage: homepage,
      actor: actor
    ).value!
  end

  def add_section!(page_recording:, section_type:, content: {}, settings: {}, enabled: true, actor:)
    RecordingStudioPages::Services::AddSection.call(
      page_recording: page_recording,
      section_type: section_type,
      content: content,
      settings: settings,
      enabled: enabled,
      actor: actor
    ).value!
  end

  MINI_PNG = ["89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000a49444154789c63000100000500010d0a2db40000000049454e44ae426082"].pack("H*")

  def attach_image!(parent_recording:, actor:, filename: "hero.png")
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(MINI_PNG),
      filename: filename,
      content_type: "image/png"
    )
    parent_recording.record_attachment_upload(
      signed_blob_id: blob.signed_id,
      name: filename,
      actor: actor
    )
  end

  def publish_page!(page_recording, slug:, actor:)
    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: page_recording,
      attributes: { slug: slug, status: "published" },
      actor: actor
    ).value!
  end

  def isolate_public_homepage!
    RecordingStudioPages::Page.where(homepage: true).update_all(homepage: false)
  end

  def record_child(recordable, root_recording, parent_recording)
    RecordingStudio.record!(
      action: "created",
      recordable: recordable,
      root_recording: root_recording,
      parent_recording: parent_recording
    ).recording
  end
end

module ActiveSupport
  class TestCase
    include PageBuilderTestHelper
  end
end
