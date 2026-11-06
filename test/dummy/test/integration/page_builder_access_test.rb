# frozen_string_literal: true

require "test_helper"

class PageBuilderAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @actor = create_actor!("pages-access@example.com")
    @root = create_workspace_root!("Visible Workspace #{SecureRandom.hex(4)}")
    @admin_root = create_admin_root!
    grant_admin!(@admin_root, @actor)
    grant_admin!(@root, @actor)
    Current.actor = @actor
    sign_in @actor
  end

  teardown do
    Current.actor = nil
  end

  test "pages index only lists pages the actor can view" do
    visible = create_page!(parent_recording: @root, title: "Mine #{SecureRandom.hex(4)}", actor: @actor)
    hidden = hidden_page_on_other_workspace

    get recording_studio_pages.admin_pages_path

    assert_response :success
    assert_includes response.body, visible.recordable.title
    refute_includes response.body, hidden.recordable.title
  end

  test "page editor 404s for a page the actor cannot view" do
    hidden = hidden_page_on_other_workspace

    get recording_studio_pages.admin_page_path(hidden)

    assert_response :not_found
  end

  test "create parents the page under a workspace the actor can edit" do
    hidden_page_on_other_workspace

    post recording_studio_pages.admin_pages_path, params: { page: { title: "Parked here #{SecureRandom.hex(4)}" } }

    assert_response :redirect
    created = RecordingStudio::Recording.order(:created_at).where(
      recordable_type: "RecordingStudioPages::Page"
    ).last
    assert_equal @root.id, created.root_recording_id
    assert_equal @root.id, created.parent_recording_id
  end

  test "staff with only the admin root cannot open another workspace page" do
    hidden = hidden_page_on_other_workspace
    staff = create_actor!("admin-only-pages@example.com")
    granted = RecordingStudioAccessible.grant_access(
      recording: @admin_root,
      actor: staff,
      role: :view,
      manager_actor: @actor
    )
    raise granted.error if granted.failure?

    sign_in staff
    Current.actor = staff

    get recording_studio_pages.admin_pages_path
    assert_response :success
    refute_includes response.body, hidden.recordable.title

    get recording_studio_pages.admin_page_path(hidden)
    assert_response :not_found
  end

  private

  def hidden_page_on_other_workspace
    other_actor = create_actor!("other-pages-#{SecureRandom.hex(4)}@example.com")
    other_root = create_workspace_root!("Hidden Workspace #{SecureRandom.hex(4)}")
    grant_admin!(other_root, other_actor)
    create_page!(
      parent_recording: other_root,
      title: "Secret #{SecureRandom.hex(4)}",
      actor: other_actor
    )
  end
end
