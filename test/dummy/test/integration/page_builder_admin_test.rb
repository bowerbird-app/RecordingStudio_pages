# frozen_string_literal: true

require "test_helper"

class PageBuilderAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @actor = create_actor!("admin-pages@example.com")
    @root = create_workspace_root!("Admin Workspace #{SecureRandom.hex(4)}")
    @admin_root = create_admin_root!
    grant_admin!(@admin_root, @actor)
    grant_admin!(@root, @actor)
    Current.actor = @actor
    sign_in @actor
  end

  teardown do
    Current.actor = nil
  end

  test "staff can create a page, add a section, reorder, disable, and delete" do
    post recording_studio_pages.admin_pages_path, params: { page: { title: "Campaign", homepage: "0" } }
    assert_response :redirect

    page_recording = RecordingStudio::Recording.order(:created_at).where(
      recordable_type: "RecordingStudioPages::Page"
    ).last
    assert_not_nil page_recording
    assert_redirected_to recording_studio_pages.admin_page_path(page_recording)

    post recording_studio_pages.admin_page_sections_path(page_recording), params: {
      section: { section_type: "hero", content: { title: "First" } }
    }
    post recording_studio_pages.admin_page_sections_path(page_recording), params: {
      section: { section_type: "rich_text", content: { title: "Second" } }
    }

    sections = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal %w[hero rich_text], sections.map { |recording| recording.recordable.section_type }

    post recording_studio_pages.move_admin_page_section_path(page_recording, sections.last, direction: "up")
    reordered = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal %w[rich_text hero], reordered.map { |recording| recording.recordable.section_type }

    post recording_studio_pages.toggle_admin_page_section_path(page_recording, reordered.first)
    assert_not reordered.first.reload.recordable.enabled?

    delete recording_studio_pages.admin_page_section_path(page_recording, reordered.first)
    remaining = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal %w[hero], remaining.map { |recording| recording.recordable.section_type }
  end

  test "visitors cannot mutate pages" do
    sign_out @actor
    page_recording = create_page!(parent_recording: @root, title: "Locked", actor: @actor)

    post recording_studio_pages.admin_pages_path, params: { page: { title: "Nope" } }
    assert_response :redirect

    post recording_studio_pages.admin_page_sections_path(page_recording), params: {
      section: { section_type: "hero", content: { title: "Nope" } }
    }
    assert_includes [401, 302, 403], response.status
  end

  test "a signed-in user without admin access is forbidden" do
    stranger = create_actor!("stranger@example.com")
    sign_in stranger

    get recording_studio_pages.admin_pages_path
    assert_response :forbidden
  end
end
