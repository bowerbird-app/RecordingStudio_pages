# frozen_string_literal: true

require "test_helper"

class PageBuilderPublicTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @actor = create_actor!("public-pages@example.com")
    Current.actor = @actor
    @root = create_workspace_root!("Public Workspace #{SecureRandom.hex(4)}")
    grant_admin!(@root, @actor)
  end

  teardown do
    Current.actor = nil
  end

  test "unpublished homepage is not public" do
    create_page!(parent_recording: @root, title: "Draft Home", homepage: true, actor: @actor)

    get root_path

    assert_response :not_found
  end

  test "published homepage renders enabled sections in order at /" do
    page_recording = create_page!(parent_recording: @root, title: "Live Home", homepage: true, actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Welcome home", body: "Built from recordings." },
      actor: @actor
    )
    add_section!(
      page_recording: page_recording,
      section_type: "rich_text",
      content: { title: "Off", body: "hidden" },
      enabled: false,
      actor: @actor
    )
    add_section!(
      page_recording: page_recording,
      section_type: "call_to_action",
      content: { title: "Publish when ready" },
      actor: @actor
    )
    publish_page!(page_recording, slug: "live-home", actor: @actor)

    get root_path

    assert_response :success
    assert_includes response.body, "Welcome home"
    assert_includes response.body, "Publish when ready"
    refute_includes response.body, "hidden"
  end

  test "published inner page is public at /pages/:uuid/:slug" do
    page_recording = create_page!(parent_recording: @root, title: "About", actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "rich_text",
      content: { title: "About us", body: "A page is a recording." },
      actor: @actor
    )
    publishable = publish_page!(page_recording, slug: "about-us", actor: @actor)

    get "/pages/#{publishable.id}/about-us"

    assert_response :success
    assert_includes response.body, "About us"
  end

  test "unpublished inner page is not public" do
    page_recording = create_page!(parent_recording: @root, title: "Secret", actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Do not leak" },
      actor: @actor
    )
    publishable = RecordingStudioPublishable::Services::Publishables::EnsureChild.call(
      parent_recording: page_recording,
      actor: @actor
    ).value!

    get "/pages/#{publishable.id}/secret"

    assert_response :not_found
  end
end
