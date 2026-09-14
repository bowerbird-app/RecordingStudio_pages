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

  test "signed-in workspace home uses a sidebar of example pages" do
    page_recording = create_page!(parent_recording: @root, title: "Tonight", actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "The floor is already warm" },
      actor: @actor
    )
    publishable = publish_page!(page_recording, slug: "tonight", actor: @actor)
    switch_to_root!(@root)

    get root_path

    assert_response :success
    assert_includes response.body, "data-controller=\"flat-pack--sidebar-layout\""
    assert_includes response.body, "Example pages"
    assert_includes response.body, "Open one from the side."
    assert_includes response.body, "Tonight"
    assert_includes response.body, "/pages/#{publishable.id}/tonight"
    assert_includes response.body, "/recording_studio_root_switchable/v1/root_switch"
    refute_includes response.body, "Page Builder studio"
    refute_includes response.body, "What's working"
    refute_includes response.body, "Next steps"
    refute_includes response.body, "The floor is already warm"
    refute_includes response.body, 'href="/admin"'
    refute_includes response.body, "data-recording-studio-default-layout"
  end

  test "signed-in admin root home is a Pages button" do
    page_recording = create_page!(parent_recording: @root, title: "About", actor: @actor)
    publishable = publish_page!(page_recording, slug: "about", actor: @actor)
    switch_to_root!(@admin_root)

    get root_path

    assert_response :success
    assert_includes response.body, "data-controller=\"flat-pack--sidebar-layout\""
    assert_includes response.body, 'href="/admin"'
    assert_includes response.body, ">Pages<"
    assert_includes response.body, "About"
    assert_includes response.body, "/pages/#{publishable.id}/about"
    refute_includes response.body, "Open one from the side."
    refute_includes response.body, "Page Builder studio"
    refute_includes response.body, "What's working"
  end

  test "studio path matches the signed-in home" do
    switch_to_root!(@root)

    get studio_path

    assert_response :success
    assert_includes response.body, "Example pages"
    assert_includes response.body, "data-controller=\"flat-pack--sidebar-layout\""
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

    get root_path

    assert_response :success
    assert_includes response.body, "Welcome home"
    refute_includes response.body, "data-controller=\"flat-pack--sidebar-layout\""
    refute_includes response.body, "Example pages"
    refute_includes response.body, 'href="/admin"'
  end
end
