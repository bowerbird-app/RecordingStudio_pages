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
    assert_includes response.body, "Add section"
    assert_includes response.body, "Hero"
    assert_includes response.body, "Call to action"
    assert_includes response.body, "add-section-#{page_recording.id}-hero"
    assert_includes response.body, 'id="page_editor"'
    assert_includes response.body, "md:grid-cols-2"
    assert_includes response.body, "Preview"
    assert_includes response.body, "Nothing live yet"
    refute_includes response.body, "Sign out"
    refute_includes response.body, "/recording_studio_root_switchable/v1/root_switch"

    post recording_studio_pages.admin_page_sections_path(page_recording),
         params: { section: { section_type: "hero" } },
         as: :turbo_stream

    assert_response :success
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, 'action="update"'
    assert_includes response.body, "page_editor"
    assert_includes response.body, "Section added."
    assert_includes response.body, "Hero"
    assert_includes response.body, "More"
    assert_includes response.body, "flat-pack--list-orderable"
    sections = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal %w[hero], sections.map { |recording| recording.recordable.section_type }
    assert_equal "Hero", sections.first.recordable.content["title"]
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
    assert_includes response.body, "Call to action"
    assert_includes response.body, "Button"
    assert_includes response.body, "Social logins"
    assert_includes response.body, "URL field"
    refute_includes response.body, "Sign out"
    refute_includes response.body, "/recording_studio_root_switchable/v1/root_switch"
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
                title: "Come as you are",
                cta: { type: "social_logins" }
              }
            }
          }

    assert_redirected_to recording_studio_pages.admin_page_path(id: page_recording.id)
    saved = section.reload.recordable.content
    assert_equal "social_logins", saved.dig("cta", "type")
    follow_redirect!
    assert_includes response.body, "Come as you are"
    assert_includes response.body, "Continue with Google"
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
    assert_includes response.body, "More"
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
    assert_includes response.body, "Preview"
    refute_includes response.body, "Nothing live yet"
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
    assert_includes response.body, "Template sections added."
    types = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
                                             .map { |recording| recording.recordable.section_type }
    assert_includes types, "hero"
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
    assert_includes response.body, "Remove page"

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
    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: @admin_root.id,
        return_to: "/studio"
      }
    }
    follow_redirect!

    get "/admin"

    assert_response :success
    assert_includes response.body, "Pages"
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
