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
    assert_includes response.body, 'data-flat-pack--icon-name-value="cog-6-tooth"'
    assert_includes response.body, "Trash"
    assert_includes response.body, "Trash this page?"
    refute_includes response.body, "Remove page"
    assert_includes response.body, "publishable_quick_actions_#{page_recording.id}"
    plus_at = response.body.index('data-flat-pack--icon-name-value="plus"')
    draft_at = response.body.index("publishable_quick_actions_#{page_recording.id}")
    cog_at = response.body.index('data-flat-pack--icon-name-value="cog-6-tooth"')
    assert_operator plus_at, :<, draft_at
    assert_operator draft_at, :<, cog_at
    assert_includes response.body, 'data-flat-pack--icon-name-value="photo"'
    assert_includes response.body, 'data-flat-pack--icon-name-value="bars-3"'
    assert_includes response.body, 'data-flat-pack--icon-name-value="document-text"'
    assert_includes response.body, "Draft"
    refute_includes response.body, "Not public yet."
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
    assert_includes response.body, 'data-flat-pack--icon-name-value="arrows-up-down"'
    assert_includes response.body, "--card-padding-md"
    hero = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload).first
    assert_includes response.body, recording_studio_pages.edit_admin_page_section_path(page_recording, hero)
    assert_equal "hero", hero.recordable.section_type
    assert_equal "Hero", hero.recordable.content["title"]

    get recording_studio_pages.edit_admin_page_section_path(page_recording, hero)
    assert_response :success
    assert_includes response.body, "Update"
  end

  test "page editor shows a Published control after the page is live" do
    page_recording = create_page!(parent_recording: @root, title: "Live control", actor: @actor)
    publish_page!(page_recording, slug: "live-control", actor: @actor)

    get recording_studio_pages.admin_page_path(page_recording)

    assert_response :success
    assert_includes response.body, "publishable_quick_actions_#{page_recording.id}"
    assert_includes response.body, "Published"
    refute_includes response.body, "Not public yet."
    refute_includes response.body, "/recordings/#{page_recording.id}/publishable/edit"
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
    assert_includes response.body, ">Style<"
    assert_includes response.body, "Preset"
    assert_includes response.body, "On a dark photo"
    assert_includes response.body, "On a light photo"
    assert_includes response.body, "Headline"
    assert_includes response.body, "Subtitle"
    assert_includes response.body, "Eyebrow"
    refute_includes response.body, "Quieter line"
    assert_select "[data-recording-studio-pages--style-fields-target=colour]", count: 3
    assert_includes response.body, "data-recording-studio-pages--style-fields-target=\"gated\""
    assert_select "[data-show-when-variant=fullscreen_image][hidden]", count: 1
    refute_includes response.body, ">Photo<"
    assert_select "[role=separator][aria-label='Call to action']", count: 1
    assert_select "[role=separator][aria-label='Style']", count: 1
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
    assert_select "[role=separator][aria-label='Call to action']", count: 1
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

  test "staff can save hero style colours" do
    page_recording = create_page!(parent_recording: @root, title: "Paint", actor: @actor)
    section = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Warm type", image: "/images/hero-tonight.jpg" },
      settings: { variant: "fullscreen_image", alignment: "left", background: "dark" },
      actor: @actor
    )

    patch recording_studio_pages.admin_page_section_path(page_id: page_recording.id, id: section.id),
          params: {
            section: {
              content: {
                title: "Warm type",
                image: "/images/hero-tonight.jpg"
              },
              settings: {
                variant: "fullscreen_image",
                alignment: "left",
                background: "light",
                eyebrow_color: "#abc",
                title_color: "#f00",
                body_color: "#334455"
              }
            }
          }

    assert_redirected_to recording_studio_pages.edit_admin_page_section_path(
      page_id: page_recording.id,
      id: section.id
    )
    saved = section.reload.recordable.settings
    assert_equal "fullscreen_image", saved["variant"]
    assert_equal "left", saved["alignment"]
    assert_equal "light", saved["background"]
    assert_equal "#aabbcc", saved["eyebrow_color"]
    assert_equal "#ff0000", saved["title_color"]
    assert_equal "#334455", saved["body_color"]
    follow_redirect!
    assert_includes response.body, "On a light photo"
    assert_select "[data-show-when-variant=fullscreen_image][hidden]", count: 0
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
    refute_includes response.body, "list-decimal"
    assert_includes response.body, "--list-item-hover-background-color"
    assert_includes response.body, 'data-flat-pack--icon-name-value="arrows-up-down"'
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

  test "the editor previews sections without a template action" do
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
    refute_includes response.body, "Use a template"
    refute_includes response.body, "apply-template-"
    refute_includes response.body, "Start from a template"
    assert_includes response.body, "orderable-url-value"
    refute_includes response.body, "Staff preview"
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

  test "staff can trash a page from the editor Settings menu" do
    page_recording = create_page!(parent_recording: @root, title: "Throw away", actor: @actor)

    get recording_studio_pages.admin_page_path(page_recording)
    assert_response :success
    assert_includes response.body, "Settings"
    assert_includes response.body, "Trash"
    assert_includes response.body, "Trash this page?"
    assert_includes response.body, "id=\"trash-page-#{page_recording.id}\""
    refute_includes response.body, "Remove page"

    get recording_studio_pages.edit_admin_page_path(page_recording)
    assert_response :success
    assert_includes response.body, "Settings"
    assert_includes response.body, "max-w-xl"
    refute_includes response.body, "Remove page"
    refute_includes response.body, "Edit page"

    delete recording_studio_pages.admin_page_path(page_recording)
    assert_redirected_to recording_studio_pages.admin_pages_path
    follow_redirect!
    assert_includes response.body, "In the trash."
    trashed = RecordingStudio::Recording.find(page_recording.id)
    assert_not_nil trashed.trashed_at
    assert trashed.trash_root
    assert RecordingStudio.capability_enabled?(:trashable, for: RecordingStudioPages::Page)
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
    refute_includes response.body, "Start from a template"
    refute_includes response.body, "template_key"
    assert_includes response.body, 'name="page[title]"'
    assert_includes response.body, "max-w-xl"
    assert_includes response.body, "flex-wrap items-center gap-3"
    assert_includes response.body, 'aria-label="Close"'
    assert_match(%r{href="/admin"(?:[\s>/])}, response.body)
    refute_includes response.body, "href=\"#{RecordingStudioPages::Admin.screen_path}\""

    list_new_page_href = RecordingStudioPages::Admin.new_page_path
    get RecordingStudioPages::Admin.screen_path
    assert_response :success
    assert_includes response.body, "Pages"
    assert_includes response.body, ">Page<"
    assert_includes response.body, "href=\"#{list_new_page_href}\""
    assert_includes response.body, 'data-flat-pack--icon-name-value="plus"'
    assert_includes response.body, "page-title-actions"
    subtitle_at = response.body.index("Compose public pages from sections.")
    page_button_at = response.body.index("href=\"#{list_new_page_href}\"")
    assert_operator subtitle_at, :<, page_button_at

    get "/admin/screens/pages/table",
        headers: { "Turbo-Frame" => "screen-table" }
    assert_response :success
    assert_includes response.body, titled.recordable.title
    assert_includes response.body, "Status"

    page_header = response.body.index("Page")
    home_header = response.body.index("Home")
    updated_header = response.body.index("Updated at")
    status_header = response.body.index("Status")
    actions_header = response.body.index("Actions")
    assert_operator page_header, :<, home_header
    assert_operator home_header, :<, updated_header
    assert_operator updated_header, :<, status_header
    assert_operator status_header, :<, actions_header
  end

  test "the Pages list can filter publishable status and home" do
    published = create_page!(parent_recording: @root, title: "Published Listed #{SecureRandom.hex(4)}", actor: @actor)
    scheduled = create_page!(parent_recording: @root, title: "Scheduled Listed #{SecureRandom.hex(4)}", actor: @actor)
    draft = create_page!(parent_recording: @root, title: "Draft Listed #{SecureRandom.hex(4)}", actor: @actor)
    home = create_page!(
      parent_recording: @root,
      title: "Home Listed #{SecureRandom.hex(4)}",
      homepage: true,
      actor: @actor
    )
    publish_page!(published, slug: "published-listed-#{SecureRandom.hex(4)}", actor: @actor)
    RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: scheduled,
      attributes: {
        slug: "scheduled-listed-#{SecureRandom.hex(4)}",
        status: "published",
        publish_at: 1.day.from_now
      },
      actor: @actor
    ).value!

    switch_to_admin_root!

    get RecordingStudioPages::Admin.screen_path
    assert_response :success
    assert_includes response.body, "Status"
    assert_includes response.body, "Draft"
    assert_includes response.body, "Scheduled"
    assert_includes response.body, "Published"
    assert_includes response.body, "Home page"
    assert_includes response.body, "Other pages"
    refute_includes response.body, ">Live<"

    get "/admin/screens/pages/table",
        params: { status: RecordingStudioPages::Composition::STATUS_DRAFT },
        headers: { "Turbo-Frame" => "screen-table" }
    assert_response :success
    assert_includes response.body, draft.recordable.title
    refute_includes response.body, published.recordable.title
    refute_includes response.body, scheduled.recordable.title
    assert_includes response.body, "Draft"
    assert_includes response.body, "publishable_quick_actions_#{draft.id}"

    get "/admin/screens/pages/table",
        params: { status: RecordingStudioPages::Composition::STATUS_PUBLISHED },
        headers: { "Turbo-Frame" => "screen-table" }
    assert_response :success
    assert_includes response.body, published.recordable.title
    refute_includes response.body, draft.recordable.title
    refute_includes response.body, scheduled.recordable.title
    assert_includes response.body, "Published"

    get "/admin/screens/pages/table",
        params: { status: RecordingStudioPages::Composition::STATUS_SCHEDULED },
        headers: { "Turbo-Frame" => "screen-table" }
    assert_response :success
    assert_includes response.body, scheduled.recordable.title
    refute_includes response.body, published.recordable.title
    refute_includes response.body, draft.recordable.title

    get "/admin/screens/pages/table",
        params: { home_page: RecordingStudioPages::Composition::HOMEPAGE_HOME },
        headers: { "Turbo-Frame" => "screen-table" }
    assert_response :success
    assert_includes response.body, home.recordable.title
    refute_includes response.body, draft.recordable.title
  end

  test "the Pages list links a live page name to the published url" do
    live = create_page!(parent_recording: @root, title: "Live Linked #{SecureRandom.hex(4)}", actor: @actor)
    draft = create_page!(parent_recording: @root, title: "Draft Plain #{SecureRandom.hex(4)}", actor: @actor)
    slug = "live-linked-#{SecureRandom.hex(4)}"
    publishable = publish_page!(live, slug: slug, actor: @actor)
    live.reload
    page_link = RecordingStudioPublishable::PageLink.for(recording: live, preview_href: "")
    public_path = RecordingStudioPages::Admin.public_page_path(live)

    assert_equal "View", page_link.text
    assert_equal page_link.href, public_path
    assert_equal "/pages/#{publishable.id}/#{slug}", public_path
    assert_nil RecordingStudioPages::Admin.public_page_path(draft)

    switch_to_admin_root!

    get "/admin/screens/pages/table",
        headers: { "Turbo-Frame" => "screen-table" }

    assert_response :success
    assert_includes response.body, live.recordable.title
    assert_includes response.body, draft.recordable.title
    title_link = response.body[/<a[^>]*href="#{Regexp.escape(public_path)}"[^>]*>\s*#{Regexp.escape(live.recordable.title)}/]
    assert title_link.present?
    assert_includes title_link, 'target="_blank"'
    assert_includes title_link, 'data-turbo="false"'
    refute_match(
      %r{href="/pages/[^"]+"[^>]*>\s*#{Regexp.escape(draft.recordable.title)}},
      response.body
    )
  end

  test "the Pages list row menu can edit and trash a page" do
    page_recording = create_page!(parent_recording: @root, title: "Row Menu #{SecureRandom.hex(4)}", actor: @actor)
    switch_to_admin_root!

    get "/admin/screens/pages/table",
        headers: { "Turbo-Frame" => "screen-table" }

    assert_response :success
    assert_includes response.body, "Edit"
    assert_includes response.body, "Trash"
    assert_includes response.body, "href=\"#{RecordingStudioPages::Admin.page_path(page_recording)}\""
    assert_includes response.body, "data-turbo-method=\"delete\""
    assert_includes response.body, "Trash this page?"
    assert_includes response.body, "Actions"

    delete recording_studio_pages.admin_page_path(page_recording)
    assert_response :redirect
    assert_nil RecordingStudio::Recording.find_by(id: page_recording.id, trashed_at: nil)
  end

  test "page builder screens close to the original trigger" do
    origin = "/"
    context = Struct.new(:params).new({ anchor_url: origin })
    unsafe = Struct.new(:params).new({ anchor_url: "javascript:alert(1)" })
    screen_context = Object.new
    def screen_context.params
      { anchor_url: "/" }
    end

    def screen_context.admin_screen_path(_key)
      "/admin/screens/pages"
    end

    assert_equal origin, RecordingStudioPages::Admin.incoming_anchor_url(context)
    assert_nil RecordingStudioPages::Admin.incoming_anchor_url(Struct.new(:params).new({}))
    assert_nil RecordingStudioPages::Admin.incoming_anchor_url(unsafe)
    assert_equal "/recording_studio_pages/admin/pages/new?anchor_url=%2F",
                 RecordingStudioPages::Admin.new_page_path(anchor_url: origin)
    refute_includes RecordingStudioPages::Admin.new_page_path(anchor_url: origin),
                    RecordingStudioPages::Admin.screen_path
    assert_equal "/admin/screens/pages?anchor_url=%2F",
                 RecordingStudioPages::Admin.screen_path_for(screen_context)

    get recording_studio_pages.new_admin_page_path, params: { anchor_url: origin }

    assert_response :success
    assert_includes response.body, 'aria-label="Close"'
    assert_match(%r{href="/"(?:[\s>])}, response.body)
    refute_includes response.body, "href=\"#{RecordingStudioPages::Admin.screen_path}\""

    get recording_studio_pages.new_admin_page_path, params: { anchor_url: "javascript:alert(1)" }

    assert_response :success
    assert_match(%r{href="/admin"(?:[\s>/])}, response.body)
    refute_includes response.body, "javascript:alert"
    refute_includes response.body, "href=\"#{RecordingStudioPages::Admin.screen_path}\""

    title = "Anchor Create #{SecureRandom.hex(4)}"
    post recording_studio_pages.admin_pages_path(anchor_url: origin), params: { page: { title: title } }

    page_recording = RecordingStudio::Recording.order(:created_at).where(
      recordable_type: "RecordingStudioPages::Page"
    ).last
    assert_redirected_to recording_studio_pages.admin_page_path(page_recording, anchor_url: origin)

    follow_redirect!
    assert_response :success
    assert_includes response.body, title
    assert_includes response.body, 'aria-label="Close"'
    assert_match(%r{href="/"(?:[\s>])}, response.body)

    get recording_studio_pages.edit_admin_page_path(page_recording, anchor_url: origin)
    assert_response :success
    assert_includes response.body, "Settings"
    assert_match(%r{href="/"(?:[\s>])}, response.body)

    switch_to_admin_root!
    root_new_page = RecordingStudioPages::Admin.new_page_path(anchor_url: origin)
    get "/admin", params: { anchor_url: origin }
    assert_response :success
    assert_includes response.body, "href=\"#{root_new_page}\""
    assert_includes response.body, "href=\"#{RecordingStudioPages::Admin.merge_anchor_url(
      RecordingStudioPages::Admin.screen_path,
      origin
    )}\""

    get "/admin/screens/pages", params: { anchor_url: origin }
    assert_response :success
    assert_includes response.body, "href=\"#{root_new_page}\""
    refute_includes response.body, RecordingStudioPages::Admin.new_page_path(
      anchor_url: RecordingStudioPages::Admin.screen_path
    )

    get "/admin/screens/pages/table",
        params: { anchor_url: origin },
        headers: { "Turbo-Frame" => "screen-table" }
    assert_response :success
    assert_includes response.body, "href=\"#{RecordingStudioPages::Admin.page_path(
      page_recording,
      anchor_url: origin
    )}\""
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
    assert_includes response.body, "Published"
    refute_includes response.body, "Live pages"
    assert_includes response.body, ">#{published_count}<"
    assert_includes response.body,
                    "href=\"#{RecordingStudioPages::Admin.screen_path(status: RecordingStudioPages::Composition::STATUS_PUBLISHED)}\""

    get "/admin/sections/pages/widgets/widgets.pages.draft_pages",
        params: { widget_view_variant: :compact },
        headers: { "Turbo-Frame" => "recording-studio-admin-widget" }

    assert_response :success
    refute_includes response.body, "aria-busy"
    assert_includes response.body, "Drafts"
    assert_includes response.body, ">#{draft_count}<"
    assert_includes response.body,
                    "href=\"#{RecordingStudioPages::Admin.screen_path(status: RecordingStudioPages::Composition::STATUS_DRAFT)}\""
  end

  test "visiting the RS Admin hub switches to the Admin root" do
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: @root.id,
        return_to: "/studio"
      }
    }
    follow_redirect!

    get "/admin", params: { anchor_url: "/" }

    assert_response :success
    assert_includes response.body, "Pages"
    assert_includes response.body, ">Page<"
    refute_equal 0, response.body.bytesize
    assert RecordingStudio::RootSwitchable::Selection.where(
      actor: @actor,
      scope_key: "all_workspaces"
    ).exists?(root_recording_id: @admin_root.id)
  end

  test "a signed-in user without Admin root access is still forbidden on the hub" do
    stranger = create_actor!("admin-hub-stranger@example.com")
    sign_in stranger

    get "/admin", params: { anchor_url: "/" }

    assert_response :forbidden
  end

  test "a workspace admin without Admin root access is still forbidden on the hub" do
    workspace_only = create_actor!("workspace-only-admin@example.com")
    grant_admin!(@root, workspace_only)
    sign_in workspace_only

    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: @root.id,
        return_to: "/studio"
      }
    }
    follow_redirect!

    get "/admin", params: { anchor_url: "/" }

    assert_response :forbidden
    assert RecordingStudio::RootSwitchable::Selection.where(
      actor: workspace_only,
      scope_key: "all_workspaces"
    ).exists?(root_recording_id: @root.id)
    refute RecordingStudio::RootSwitchable::Selection.where(
      actor: workspace_only,
      scope_key: "all_workspaces"
    ).exists?(root_recording_id: @admin_root.id)
  end
end
