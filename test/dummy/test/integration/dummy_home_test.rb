# frozen_string_literal: true

require "test_helper"

class DummyHomeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @actor = create_actor!("dummy-home@example.com")
    Current.actor = @actor
    @root = create_workspace_root!("Home Workspace #{SecureRandom.hex(4)}")
    @admin_root = create_admin_root!
    grant_admin!(@root, @actor)
    grant_admin!(@admin_root, @actor)
    isolate_public_homepage!
    sign_in @actor
  end

  teardown do
    Current.actor = nil
  end

  test "signed-in home is a sidebar shell with example page buttons" do
    page_recording = create_page!(parent_recording: @root, title: "Tonight", actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "The floor is already warm" },
      actor: @actor
    )
    publishable = publish_page!(page_recording, slug: "tonight", actor: @actor)
    homepage = create_page!(parent_recording: @root, title: "Home", homepage: true, actor: @actor)
    publish_page!(homepage, slug: "home", actor: @actor)

    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: @root.id,
        return_to: "/studio"
      }
    }
    assert_redirected_to "/studio"
    follow_redirect!

    assert_response :success
    assert_includes response.body, "data-controller=\"flat-pack--sidebar-layout\""
    assert_includes response.body, @root.recordable.name
    assert_includes response.body, "Tonight"
    assert_includes response.body, "/pages/#{publishable.id}/tonight"
    assert_includes response.body, 'href="/site"'
    assert_includes response.body, "Home"
    assert_includes response.body, "recording-studio-root-switchable--root-switch-dropdown"
    assert_includes response.body, 'href="/admin?anchor_url=%2F"'
    assert_includes response.body, 'href="/recording_studio_pages/admin/pages?anchor_url=%2F"'
    refute_includes response.body, "Page Builder studio"
    refute_includes response.body, "What's working"
    refute_includes response.body, "Next steps"
    refute_includes response.body, "The floor is already warm"
    refute_includes response.body, "data-recording-studio-default-layout"

    get "/"

    assert_response :success
    assert_includes response.body, "data-controller=\"flat-pack--sidebar-layout\""
    assert_includes response.body, @root.recordable.name
  end

  test "studio path matches the signed-in home" do
    get "/studio"

    assert_response :success
    assert_includes response.body, "data-controller=\"flat-pack--sidebar-layout\""
    assert_includes response.body, "recording-studio-root-switchable--root-switch-dropdown"
  end

  test "signed-in people can still open the live site" do
    page_recording = create_page!(parent_recording: @root, title: "Live Home", homepage: true, actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Welcome home" },
      actor: @actor
    )
    publish_page!(page_recording, slug: "live-home", actor: @actor)

    get "/site"

    assert_response :success
    assert_includes response.body, "Welcome home"
    refute_includes response.body, "data-controller=\"flat-pack--sidebar-layout\""
    refute_includes response.body, @root.recordable.name
  end

  test "visitors still see the published homepage at /" do
    page_recording = create_page!(parent_recording: @root, title: "Live Home", homepage: true, actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Welcome home" },
      actor: @actor
    )
    publish_page!(page_recording, slug: "live-home", actor: @actor)
    sign_out @actor
    Current.actor = nil

    get "/"

    assert_response :success
    assert_includes response.body, "Welcome home"
    refute_includes response.body, "data-controller=\"flat-pack--sidebar-layout\""
    refute_includes response.body, @root.recordable.name
    refute_includes response.body, 'href="/admin"'
  end
end
