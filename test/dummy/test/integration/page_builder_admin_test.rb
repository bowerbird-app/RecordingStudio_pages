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

    patch recording_studio_pages.reorder_admin_page_sections_path(page_recording),
          params: { moving_recording_id: sections.last.id, target_position: 1 },
          headers: { "Accept" => "application/json" }
    assert_response :success
    assert_equal true, response.parsed_body["ok"]
    reordered = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal %w[rich_text hero], reordered.map { |recording| recording.recordable.section_type }

    post recording_studio_pages.toggle_admin_page_section_path(page_recording, reordered.first)
    assert_not reordered.first.reload.recordable.enabled?

    delete recording_studio_pages.admin_page_section_path(page_recording, reordered.first)
    remaining = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal %w[hero], remaining.map { |recording| recording.recordable.section_type }
  end

  test "staff can duplicate a section" do
    page_recording = create_page!(parent_recording: @root, title: "Dup", actor: @actor)
    section = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Copy me" },
      actor: @actor
    )

    post recording_studio_pages.duplicate_admin_page_section_path(page_recording, section)
    assert_response :redirect
    follow_redirect!
    assert_includes response.body, "Section copied."

    sections = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal %w[hero hero], sections.map { |recording| recording.recordable.section_type }
    assert_equal "Copy me", sections.last.recordable.content["title"]
    assert_not_equal section.recordable_id, sections.last.recordable_id
    assert sections.last.events.exists?(action: "duplicated")
  end

  test "staff can add a section from the editor dropdown" do
    page_recording = create_page!(parent_recording: @root, title: "Library", actor: @actor)

    get recording_studio_pages.admin_page_path(page_recording)

    assert_response :success
    assert_includes response.body, "Section"
    assert_includes response.body, 'data-flat-pack--icon-name-value="plus"'
    assert_includes response.body, "Hero"
    assert_includes response.body, "Menu"
    assert_includes response.body, "Call to action"
    assert_includes response.body, "add-section-#{page_recording.id}-hero"
    assert_includes response.body, 'id="page_editor"'
    assert_select "#flash", count: 1
    assert_includes response.body, "md:grid-cols-2"
    refute_includes response.body, "Off sections stay off"
    assert_includes response.body, "Add your first section"
    assert_includes response.body, "Preview"
    assert_includes response.body, "Settings"
    refute_includes response.body, "Add section"
    refute_includes response.body, "Edit page"
    refute_includes response.body, "Nothing live yet"
    refute_includes response.body, "Nothing here yet"
    refute_includes response.body, "--card-padding-md"
    refute_includes response.body, "Sign out"
    refute_includes response.body, "/recording_studio_root_switchable/v1/root_switch"

    post recording_studio_pages.admin_page_sections_path(page_recording),
         params: { section: { section_type: "hero" } },
         as: :turbo_stream

    assert_response :success
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, 'action="replace"'
    assert_includes response.body, 'action="update"'
    assert_includes response.body, 'target="flash"'
    assert_includes response.body, "page_editor"
    assert_select "turbo-stream[target=flash]", text: /Section added/
    assert_select "turbo-stream[target=page_editor]"
    refute_includes css_select("turbo-stream[target=page_editor]").text, "Section added."
    assert_includes response.body, "Hero"
    refute_includes response.body, "More"
    assert_includes response.body, "ellipsis-horizontal"
    assert_includes response.body, "flat-pack--list-orderable"
    assert_includes response.body, "--card-padding-md"
    sections = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal %w[hero], sections.map { |recording| recording.recordable.section_type }
    assert_equal "Hero", sections.first.recordable.content["title"]
  end

  test "page editor keeps one flash slot after create and add section" do
    post recording_studio_pages.admin_pages_path, params: { page: { title: "Flash slot", homepage: "0" } }
    follow_redirect!

    assert_response :success
    assert_select "#flash", count: 1
    assert_includes css_select("#flash").text, "Page created."
    refute_includes css_select("#page_editor").text, "Page created."

    page_recording = RecordingStudio::Recording.order(:created_at).where(
      recordable_type: "RecordingStudioPages::Page"
    ).last

    post recording_studio_pages.admin_page_sections_path(page_recording),
         params: { section: { section_type: "hero" } },
         as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[target=flash]", count: 1
    assert_select "turbo-stream[target=flash]", text: /Section added/
    refute_includes css_select("turbo-stream[target=page_editor]").text, "Section added."
    refute_includes css_select("turbo-stream[target=page_editor]").text, "Page created."
  end

  test "staff can open a generated hero editor after adding a section" do
    page_recording = create_page!(parent_recording: @root, title: "Hero form", actor: @actor)
    post recording_studio_pages.admin_page_sections_path(page_recording), params: {
      section: { section_type: "hero" }
    }
    follow_redirect!

    section = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload).first
    get recording_studio_pages.edit_admin_page_section_path(page_id: page_recording.id, id: section.id)

    assert_response :success
    assert_includes response.body, "Title"
    assert_includes response.body, "Layout"
    assert_includes response.body, "Align"
    assert_includes response.body, "Photo"
    assert_includes response.body, "Call to action"
    assert_includes response.body, "Button"
    assert_includes response.body, "Social logins"
    assert_includes response.body, "URL field"
    assert_includes response.body, "md:grid-cols-2"
    assert_includes response.body, "max-h-[80vh]"
    assert_includes response.body, "md:sticky"
    refute_includes response.body, "Nothing to preview"
    assert_includes response.body, "Hero"
    assert_includes response.body, ">Update<"
    assert_includes response.body, ">Cancel<"
    assert_includes response.body, "Choose image"
    refute_includes response.body, "Image url"
    refute_includes response.body, "Sign out"
    refute_includes response.body, "/recording_studio_root_switchable/v1/root_switch"
  end

  test "staff can open a generated menu editor after adding a section" do
    page_recording = create_page!(parent_recording: @root, title: "Menu form", actor: @actor)
    post recording_studio_pages.admin_page_sections_path(page_recording), params: {
      section: { section_type: "top_nav" }
    }
    follow_redirect!

    section = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload).first
    get recording_studio_pages.edit_admin_page_section_path(page_id: page_recording.id, id: section.id)

    assert_response :success
    assert_includes response.body, "Name"
    assert_includes response.body, "Mark"
    assert_includes response.body, "Add link"
    assert_includes response.body, "Label"
    assert_includes response.body, "Join"
    assert_includes response.body, "Choose image"
    refute_includes response.body, "Layout"
    refute_includes response.body, "recordable"
  end

  test "the section editor previews a turned-off section" do
    page_recording = create_page!(parent_recording: @root, title: "Off preview", actor: @actor)
    section = add_section!(
      page_recording: page_recording,
      section_type: "rich_text",
      content: { title: "Quiet notes", body: "Still worth a look." },
      settings: { variant: "narrow" },
      enabled: false,
      actor: @actor
    )

    get recording_studio_pages.edit_admin_page_section_path(page_id: page_recording.id, id: section.id)

    assert_response :success
    assert_includes response.body, "md:grid-cols-2"
    assert_includes response.body, "Quiet notes"
    assert_includes response.body, "Still worth a look."
    assert_includes response.body, "max-w-prose"
    assert_includes response.body, ">Update<"
    assert_includes response.body, ">Cancel<"
    assert_includes response.body, 'form="section-editor"'
    assert_includes response.body, 'data-turbo="false"'
    refute_includes response.body, "Save section"
    refute_includes response.body, "Nothing to preview"
    assert_includes response.body, "Full width"
    assert_includes response.body, "Background"
    assert_includes response.body, "Muted"
    assert_includes response.body, "Inverted"
    assert_includes response.body, "Choose image"
  end

  test "staff can change a hero call to action" do
    page_recording = create_page!(parent_recording: @root, title: "Swap CTA", actor: @actor)
    section = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: {
        title: "Come as you are",
        cta: { type: "button", text: "Come in", url: "/users/sign_in" }
      },
      actor: @actor
    )

    patch recording_studio_pages.admin_page_section_path(page_id: page_recording.id, id: section.id),
          params: {
            section: {
              content: {
                title: "Doors open",
                cta: { type: "social_logins" }
              }
            }
          }

    assert_redirected_to recording_studio_pages.edit_admin_page_section_path(
      page_id: page_recording.id,
      id: section.id
    )
    saved = section.reload.recordable.content
    assert_equal "social_logins", saved.dig("cta", "type")
    assert_equal "Doors open", saved["title"]
    follow_redirect!
    assert_includes response.body, "Updated."
    assert_includes response.body, "Doors open"
    refute_includes response.body, "Come as you are"
    assert_includes response.body, "Continue with Google"
    assert_includes response.body, ">Update<"
  end

  test "the add section library redirects to the page editor" do
    page_recording = create_page!(parent_recording: @root, title: "Redirect", actor: @actor)

    get recording_studio_pages.new_admin_page_section_path(page_recording)

    assert_redirected_to recording_studio_pages.admin_page_path(id: page_recording.id)
  end

  test "staff can drag-reorder sections through the list endpoint" do
    page_recording = create_page!(parent_recording: @root, title: "Order", actor: @actor)
    first = add_section!(page_recording: page_recording, section_type: "hero", content: { title: "First" }, actor: @actor)
    second = add_section!(
      page_recording: page_recording,
      section_type: "rich_text",
      content: { title: "Second" },
      actor: @actor
    )

    get recording_studio_pages.admin_page_path(page_recording)
    assert_includes response.body, first.id.to_s
    assert_includes response.body, 'role="list"'
    refute_includes response.body, "More"
    assert_includes response.body, "ellipsis-horizontal"
    assert_includes response.body, "Copy"
    assert_includes response.body, "data-controller=\"recording-studio-pages--section-list\""
    assert_includes response.body, "flat-pack--list-orderable"
    assert_includes response.body, "orderable-url-value"
    assert_includes response.body, "list-decimal"
    refute_includes response.body, "Move up"
    refute_includes response.body, "Move down"

    patch recording_studio_pages.reorder_admin_page_sections_path(page_recording),
          params: { moving_recording_id: second.id, target_position: 1 },
          headers: { "Accept" => "application/json" }

    assert_response :success
    assert_equal true, response.parsed_body["ok"]
    ordered = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal [second.id, first.id], ordered.map(&:id)

    patch recording_studio_pages.reorder_admin_page_sections_path(page_recording),
          params: { moving_recording_id: second.id, target_position: 0 },
          headers: { "Accept" => "application/json" }
    assert_response :unprocessable_content
    assert_equal false, response.parsed_body["ok"]
  end

  test "the editor previews sections and can apply a template" do
    page_recording = create_page!(parent_recording: @root, title: "Preview me", actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "rich_text",
      content: { title: "Visible notes", body: "Staff can read this." },
      settings: { variant: "narrow" },
      actor: @actor
    )
    add_section!(
      page_recording: page_recording,
      section_type: "image_text",
      content: { title: "Photo on the right", image_url: "https://example.com/photo.png" },
      settings: { variant: "image_right" },
      actor: @actor
    )

    get recording_studio_pages.admin_page_path(page_recording)

    assert_response :success
    assert_includes response.body, "md:grid-cols-2"
    refute_includes response.body, "Off sections stay off"
    refute_includes response.body, "Nothing live yet"
    refute_includes response.body, "Add your first section"
    assert_includes response.body, "Visible notes"
    assert_includes response.body, "Staff can read this."
    assert_includes response.body, "max-w-prose"
    assert_includes response.body, "Use a template"
    assert_includes response.body, "apply-template-#{page_recording.id}-marketing_home"
    assert_includes response.body, "apply-template-#{page_recording.id}-full_bleed_hero"
    assert_includes response.body, "apply-template-#{page_recording.id}-join"
    assert_includes response.body, "apply-template-#{page_recording.id}-walk_in"
    assert_includes response.body, "apply-template-#{page_recording.id}-start_from_url"
    assert_includes response.body, "orderable-url-value"
    refute_includes response.body, "Staff preview"

    post recording_studio_pages.apply_template_admin_page_path(page_recording),
         params: { template_key: "marketing_home" },
         as: :turbo_stream

    assert_response :success
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, 'target="flash"'
    assert_select "turbo-stream[target=flash]", text: /Template sections added/
    refute_includes css_select("turbo-stream[target=page_editor]").text, "Template sections added."
    types = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
                                             .map { |recording| recording.recordable.section_type }
    assert_includes types, "hero"
    assert_includes types, "top_nav"
    assert_includes types, "call_to_action"
  end

  test "copied sections stay last in the orderable list" do
    page_recording = create_page!(parent_recording: @root, title: "Copy last", actor: @actor)
    first = add_section!(page_recording: page_recording, section_type: "hero", content: { title: "First" }, actor: @actor)
    second = add_section!(
      page_recording: page_recording,
      section_type: "rich_text",
      content: { title: "Second" },
      actor: @actor
    )

    post recording_studio_pages.duplicate_admin_page_section_path(page_recording, first)
    follow_redirect!

    ordered = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal [first.id, second.id, ordered.last.id], ordered.map(&:id)
    assert_equal "First", ordered.last.recordable.content["title"]
    refute_equal first.id, ordered.last.id
  end

  test "staff can remove a page from edit" do
    page_recording = create_page!(parent_recording: @root, title: "Throw away", actor: @actor)

    get recording_studio_pages.edit_admin_page_path(page_recording)
    assert_response :success
    assert_includes response.body, "Settings"
    assert_includes response.body, "Remove page"
    refute_includes response.body, "Edit page"

    delete recording_studio_pages.admin_page_path(page_recording)
    assert_redirected_to recording_studio_pages.admin_pages_path
    follow_redirect!
    assert_includes response.body, "Page removed."
    assert_nil RecordingStudio::Recording.find_by(id: page_recording.id, trashed_at: nil)
  end

  test "empty pages index uses a Flatpack alert description" do
    RecordingStudioPages::Page.update_all(title: "Not empty #{SecureRandom.hex(4)}")
    RecordingStudio::Recording.where(recordable_type: "RecordingStudioPages::Page").update_all(trashed_at: Time.current)

    get recording_studio_pages.admin_pages_path

    assert_response :success
    assert_includes response.body, "Nothing here yet"
    assert_includes response.body, "Add a page to get going."
    assert_includes response.body, ">Page<"
    assert_includes response.body, 'data-flat-pack--icon-name-value="plus"'
    refute_includes response.body, "New page"
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

    patch recording_studio_pages.reorder_admin_page_sections_path(page_recording),
          params: { moving_recording_id: "missing", target_position: 1 },
          headers: { "Accept" => "application/json" }
    assert_includes [401, 302, 403], response.status

    post recording_studio_pages.duplicate_admin_page_section_path(page_recording, "missing")
    assert_includes [401, 302, 403], response.status
  end

  test "a signed-in user without admin access is forbidden" do
    stranger = create_actor!("stranger@example.com")
    sign_in stranger

    get recording_studio_pages.admin_pages_path
    assert_response :forbidden
  end

  test "the RS Admin hub opens after switching to the Admin root" do
    switch_to_admin_root!

    get "/admin"

    assert_response :success
    assert_includes response.body, "Pages"
    assert_includes response.body, ">Page<"
    assert_includes response.body, "View all"
    refute_includes response.body, "View pages"
    refute_includes response.body, "New page"

    page_href = RecordingStudioPages::Admin.new_page_path
    view_all_href = RecordingStudioPages::Admin.screen_path
    assert_includes response.body, "href=\"#{page_href}\""
    assert_includes response.body, "href=\"#{view_all_href}\""
    assert_operator response.body.index("href=\"#{page_href}\""), :<, response.body.index("href=\"#{view_all_href}\"")
    assert_includes response.body, 'data-flat-pack--icon-name-value="plus"'
  end

  test "Pages hub Page opens the new page form and View all opens the Admin list" do
    titled = create_page!(parent_recording: @root, title: "Hub Listed #{SecureRandom.hex(4)}", actor: @actor)
    switch_to_admin_root!

    get RecordingStudioPages::Admin.new_page_path
    assert_response :success
    assert_includes response.body, "Give it a name"
    assert_includes response.body, 'name="page[title]"'
    assert_includes response.body, "max-w-xl"
    assert_includes response.body, "flex-wrap items-center gap-3"

    get RecordingStudioPages::Admin.screen_path
    assert_response :success
    assert_includes response.body, "Pages"
    assert_includes response.body, ">Page<"
    assert_includes response.body, "href=\"#{RecordingStudioPages::Admin.new_page_path}\""
    assert_includes response.body, 'data-flat-pack--icon-name-value="plus"'

    get "/admin/screens/pages/table",
        headers: { "Turbo-Frame" => "screen-table" }
    assert_response :success
    assert_includes response.body, titled.recordable.title
  end

  test "creating a page without ticking home still saves from the Admin root" do
    switch_to_admin_root!
    title = "Hub Create #{SecureRandom.hex(4)}"

    post recording_studio_pages.admin_pages_path, params: { page: { title: title } }

    assert_response :redirect
    page_recording = RecordingStudio::Recording.order(:created_at).where(
      recordable_type: "RecordingStudioPages::Page"
    ).last
    assert_equal title, page_recording.recordable.title
    assert_equal false, page_recording.recordable.homepage?
    follow_redirect!
    assert_response :success
    assert_includes response.body, title
  end

  test "pages hub widgets resolve live and draft counts instead of staying on the shimmer" do
    live = create_page!(parent_recording: @root, title: "Live Hub #{SecureRandom.hex(4)}", actor: @actor)
    create_page!(parent_recording: @root, title: "Draft Hub #{SecureRandom.hex(4)}", actor: @actor)
    publish_page!(live, slug: "live-hub-#{SecureRandom.hex(4)}", actor: @actor)

    switch_to_admin_root!

    get "/admin"

    assert_response :success
    assert_includes response.body, "@hotwired/turbo-rails"
    assert_includes response.body, "controllers/recording_studio_admin/async_widgets_controller"
    assert_includes response.body, 'data-controller="recording-studio-admin--async-widgets"'
    assert_includes response.body, "aria-busy"
    assert_includes response.body, "/admin/sections/pages/widgets/widgets.pages.published_pages"
    assert_includes response.body, "/admin/sections/pages/widgets/widgets.pages.draft_pages"

    published_count = RecordingStudioPages::Composition.published_pages_count
    draft_count = RecordingStudioPages::Composition.draft_pages_count

    get "/admin/sections/pages/widgets/widgets.pages.published_pages",
        params: { widget_view_variant: :compact },
        headers: { "Turbo-Frame" => "recording-studio-admin-widget" }

    assert_response :success
    refute_includes response.body, "aria-busy"
    assert_includes response.body, "Live pages"
    assert_includes response.body, ">#{published_count}<"

    get "/admin/sections/pages/widgets/widgets.pages.draft_pages",
        params: { widget_view_variant: :compact },
        headers: { "Turbo-Frame" => "recording-studio-admin-widget" }

    assert_response :success
    refute_includes response.body, "aria-busy"
    assert_includes response.body, "Drafts"
    assert_includes response.body, ">#{draft_count}<"
  end

  test "the RS Admin hub is forbidden while the current root is a workspace" do
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: @root.id,
        return_to: "/studio"
      }
    }
    follow_redirect!

    get "/admin"

    assert_response :forbidden
  end
end
