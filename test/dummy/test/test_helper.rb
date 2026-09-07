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

    RecordingStudioAccessible::AccessCreationContext.allow do
      root_recording = RecordingStudio.root_recording_or_self(recording)
      root_recording.record(RecordingStudio::Access, parent_recording: recording) do |access|
        access.actor = actor
        access.role = :admin
      end
    end
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
