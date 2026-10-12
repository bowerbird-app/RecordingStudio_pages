# frozen_string_literal: true

require "test_helper"

# Render-level English for Admin DSL callables (titles, subtitles, widgets, row
# actions, trash confirm, Home badge) and setting/CTA <select> option HTML.
class PagesAdminI18nRenderTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @actor = create_actor!("admin-i18n-render@example.com")
    @root = create_workspace_root!("Admin I18n Workspace #{SecureRandom.hex(4)}")
    @admin_root = create_admin_root!
    grant_admin!(@admin_root, @actor)
    grant_admin!(@root, @actor)
    Current.actor = @actor
    sign_in @actor
  end

  teardown do
    Current.actor = nil
  end

  def switch_to_admin_root!
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: @admin_root.id,
        return_to: "/admin"
      }
    }
    follow_redirect!
  end

  test "admin search for compose finds Pages via plain screen subtitle" do
    switch_to_admin_root!

    screen = RecordingStudioPages::Admin::PagesScreen
    assert_instance_of String, screen.subtitle
    refute_match(/#<Proc/i, screen.subtitle.to_s)

    get "/admin/sections", params: { q: "compose" }
    assert_response :success
    assert_includes response.body, "Pages"
    refute_includes response.body, "#<Proc"
    # Search hit comes from screen subtitle indexed as a plain string.
    assert_match(/compose public pages from sections/i, response.body)
  end

  test "admin hub section and widgets render evaluated english never Proc" do
    switch_to_admin_root!

    get "/admin"
    assert_response :success
    assert_includes response.body, "Pages"
    assert_includes response.body, "Compose public pages from registered sections"
    assert_includes response.body, "View all"
    assert_includes response.body, ">Page<"
    refute_includes response.body, "#<Proc"

    get "/admin/sections/pages/widgets/widgets.pages.published_pages",
        params: { widget_view_variant: :compact },
        headers: { "Turbo-Frame" => "recording-studio-admin-widget" }
    assert_response :success
    assert_includes response.body, "Published"
    assert_includes response.body, "Pages that are on the public site."
    refute_includes response.body, "#<Proc"

    get "/admin/sections/pages/widgets/widgets.pages.draft_pages",
        params: { widget_view_variant: :compact },
        headers: { "Turbo-Frame" => "recording-studio-admin-widget" }
    assert_response :success
    assert_includes response.body, "Drafts"
    assert_includes response.body, "Pages that are still a draft."
    refute_includes response.body, "#<Proc"
  end

  test "admin pages screen table renders english actions confirm and home badge" do
    home = create_page!(
      parent_recording: @root,
      title: "Home Badge #{SecureRandom.hex(4)}",
      homepage: true,
      actor: @actor
    )
    create_page!(parent_recording: @root, title: "Other #{SecureRandom.hex(4)}", actor: @actor)
    switch_to_admin_root!

    get RecordingStudioPages::Admin.screen_path
    assert_response :success
    assert_includes response.body, "Pages"
    assert_includes response.body, "Compose public pages from sections."
    assert_includes response.body, ">Page<"
    refute_includes response.body, "#<Proc"

    get "/admin/screens/pages/table",
        headers: { "Turbo-Frame" => "screen-table" }
    assert_response :success
    assert_includes response.body, "Edit"
    assert_includes response.body, "Trash"
    assert_includes response.body, "Trash this page?"
    assert_includes response.body, "data-turbo-confirm=\"Trash this page?\""
    assert_includes response.body, home.recordable.title
    # Homepage badge cell (column header "Home" also present; badge is the translated copy).
    assert_match(/\bHome\b/, response.body)
    refute_includes response.body, "#<Proc"
  end

  test "section setting and cta select html keeps main english option values and labels" do
    page_recording = create_page!(parent_recording: @root, title: "Select parity #{SecureRandom.hex(4)}", actor: @actor)
    post recording_studio_pages.admin_page_sections_path(page_recording), params: {
      section: { section_type: "hero" }
    }
    follow_redirect!
    section = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload).first

    get recording_studio_pages.edit_admin_page_section_path(page_id: page_recording.id, id: section.id)
    assert_response :success

    assert_select "select[name='section[settings][alignment]']" do
      assert_select "option[value='center']", text: "Center"
      assert_select "option[value='left']", text: "Left"
    end

    assert_select "select[name='section[settings][background]']" do
      assert_select "option[value='dark']", text: "On a dark photo"
      assert_select "option[value='light']", text: "On a light photo"
    end

    cta_keys = RecordingStudioPages.ctas.map(&:key)
    assert_includes cta_keys, "button"
    assert_select "select[name='section[content][cta][type]']" do
      RecordingStudioPages.ctas.each do |definition|
        assert_select "option[value=?]", definition.key, text: definition.name
      end
    end
  end
end
