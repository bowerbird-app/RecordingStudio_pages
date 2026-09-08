# frozen_string_literal: true

require "test_helper"

class RecordingStudioTemplateTest < ActiveSupport::TestCase
  test "dummy app loads root switchable config and controller support" do
    assert_equal [ "all_workspaces" ], RecordingStudioRootSwitchable.configuration.scopes.keys
    assert_equal :application_layout, RecordingStudioRootSwitchable.configuration.layout
    assert_includes ApplicationController.ancestors, RecordingStudio::RootSwitchable::ControllerSupport
    assert_includes ApplicationController.ancestors, RecordingStudio::UsesDefaultLayout
  end

  test "dummy app validates recordable declarations" do
    assert RecordingStudio.validate_recordable_declarations!
    assert_equal %w[AdminRoot RecordingStudioUser::People Workspace].sort, RecordingStudio.root_recordable_types.sort
    assert_equal %w[Workspace Folder], RecordingStudio.allowed_parent_types_for("RecordingStudioPages::Page")
  end

  test "dummy app schema keeps accessible grants and page builder tables" do
    connection = ActiveRecord::Base.connection

    assert connection.column_exists?(:recording_studio_recordings, :root_recording_id)
    assert connection.table_exists?(:recording_studio_accesses)
    assert connection.table_exists?(:recording_studio_pages_pages)
    assert connection.table_exists?(:recording_studio_pages_sections)
    assert connection.column_exists?(:recording_studio_recordings, :recording_studio_orderable_position)
    assert connection.table_exists?(:recording_studio_publishable_publishables)
    assert connection.table_exists?(:recording_studio_attachable_attachments)
    assert connection.table_exists?(:recording_studio_user_people)
    assert connection.table_exists?(:recording_studio_user_profiles)
    assert connection.table_exists?(:recording_studio_user_identities)
    assert connection.column_exists?(:recording_studio_accesses, :depends_on_recording_id)
    refute connection.table_exists?(:pages)
    refute connection.table_exists?(:recording_studio_access_boundaries)
    refute connection.table_exists?(:recording_studio_device_sessions)
  end

  test "dummy seeds use hierarchy idempotently and restore current actor" do
    Current.actor = nil

    load Rails.root.join("db/seeds.rb").to_s

    workspace = Workspace.find_by!(name: "Studio Workspace")
    accessible_workspace = Workspace.find_by!(name: "Client Workspace")
    private_workspace = Workspace.find_by!(name: "Private Workspace")
    folder = Folder.find_by!(name: "Product Docs")
    root_recording = RecordingStudio::Recording.find_by!(recordable: workspace)
    accessible_root_recording = RecordingStudio::Recording.find_by!(recordable: accessible_workspace)
    private_root_recording = RecordingStudio::Recording.find_by!(recordable: private_workspace)
    folder_recording = RecordingStudio::Recording.find_by!(recordable: folder)
    homepage_recording = RecordingStudio::Recording.where(
      recordable_type: "RecordingStudioPages::Page",
      trashed_at: nil
    ).includes(:recordable).find { |recording| recording.recordable&.title == "Home" }
    tonight_recording = RecordingStudio::Recording.where(
      recordable_type: "RecordingStudioPages::Page",
      trashed_at: nil
    ).includes(:recordable).find { |recording| recording.recordable&.title == "Tonight" }
    assert_not_nil homepage_recording
    assert_not_nil tonight_recording
    homepage = homepage_recording.recordable
    tonight_sections = RecordingStudioPages::Composition.section_recordings_for(tonight_recording)
    tonight_hero = tonight_sections.first.recordable

    assert_nil Current.actor
    assert_nil root_recording.parent_recording_id
    assert_nil accessible_root_recording.parent_recording_id
    assert_nil private_root_recording.parent_recording_id
    assert_equal root_recording, folder_recording.parent_recording
    assert_equal root_recording, folder_recording.root_recording
    assert_equal root_recording, homepage_recording.parent_recording
    assert_equal root_recording, homepage_recording.root_recording
    assert homepage.homepage?
    homepage_types = RecordingStudioPages::Composition.section_recordings_for(homepage_recording)
                                                      .map { |recording| recording.recordable.section_type }
    homepage_hero = RecordingStudioPages::Composition.section_recordings_for(homepage_recording)
                                                     .find { |recording| recording.recordable.section_type == "hero" }
                                                     &.recordable
    assert_equal %w[hero logo_cloud feature_grid call_to_action], homepage_types
    assert_equal "The page is the front door", homepage_hero.content["title"]
    assert_equal "button", homepage_hero.content.dig("cta", "type")
    assert_equal "Come in", homepage_hero.content.dig("cta", "text")
    join_recording = RecordingStudio::Recording.where(
      recordable_type: "RecordingStudioPages::Page",
      trashed_at: nil
    ).includes(:recordable).find { |recording| recording.recordable&.title == "Join" }
    start_recording = RecordingStudio::Recording.where(
      recordable_type: "RecordingStudioPages::Page",
      trashed_at: nil
    ).includes(:recordable).find { |recording| recording.recordable&.title == "Start from a URL" }
    assert_not_nil join_recording
    assert_not_nil start_recording
    join_hero = RecordingStudioPages::Composition.section_recordings_for(join_recording)
                                                 .find { |recording| recording.recordable.section_type == "hero" }
                                                 &.recordable
    start_hero = RecordingStudioPages::Composition.section_recordings_for(start_recording)
                                                  .find { |recording| recording.recordable.section_type == "hero" }
                                                  &.recordable
    assert_equal "social_logins", join_hero.content.dig("cta", "type")
    assert_equal "url_form", start_hero.content.dig("cta", "type")
    assert_equal 1, tonight_sections.size
    assert_equal "hero", tonight_hero.section_type
    assert_equal "fullscreen_image", tonight_hero.settings["variant"]
    assert_equal "/images/hero-tonight.jpg", tonight_hero.content["image_url"]
    assert_equal "The floor is already warm", tonight_hero.content["title"]
    assert_equal 3, Workspace.count
    assert_not_nil RecordingStudioUser.profile_for(User.find_by!(email: "admin@admin.com"))

    assert_no_difference -> { User.count } do
      assert_no_difference -> { RecordingStudio::Recording.count } do
        load Rails.root.join("db/seeds.rb").to_s
      end
    end
    assert_nil Current.actor
  ensure
    Current.actor = nil
  end

  test "workspace opts into accessible without enabling it globally" do
    workspace_source = File.read(Rails.root.join("app/models/workspace.rb"))

    assert_includes workspace_source, "enable_capability(:accessible, on: self)"
    refute File.exist?(RecordingStudioPages::Engine.root.join("lib/recording_studio_pages/capabilities/example.rb"))

    assert RecordingStudio.capability_enabled?(:accessible, for: Workspace)
    refute RecordingStudio.capability_enabled?(:accessible, for: Folder)
    refute RecordingStudio.capability_enabled?(:accessible, for: RecordingStudioPages::Page)
    assert RecordingStudio.capability_enabled?(:duplicatable, for: RecordingStudioPages::Section)
    refute RecordingStudio.capability_enabled?(:duplicatable, for: RecordingStudioPages::Page)
    assert_includes ApplicationController.ancestors, RecordingStudio::UsesDefaultLayout
  end

  test "dummy app mounts duplicatable for section copy" do
    routes = File.read(Rails.root.join("config/routes.rb"))

    assert defined?(RecordingStudioDuplicatable)
    assert_includes routes, "RecordingStudioDuplicatable::Engine"
    assert RecordingStudio.capability_enabled?(:duplicatable, for: RecordingStudioPages::Section)
  end

  test "dummy host registers extra hero CTAs and templates" do
    assert RecordingStudioPages.cta?(:button)
    assert RecordingStudioPages.cta?(:social_logins)
    assert RecordingStudioPages.cta?(:url_form)
    assert_equal "join", RecordingStudioPages.template(:join).key
    assert_equal "start_from_url", RecordingStudioPages.template(:start_from_url).key
    routes = File.read(Rails.root.join("config/routes.rb"))

    assert_includes routes, 'get "/start"'
    assert_includes routes, "recording_studio_user_auth_for :users"
    assert_includes routes, "RecordingStudioUser::Engine"
  end
end
