# frozen_string_literal: true

require "test_helper"

class NestedSectionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @actor = create_actor!("nested-sections@example.com")
    @root = create_workspace_root!("Nested Workspace #{SecureRandom.hex(4)}")
    @admin_root = create_admin_root!
    grant_admin!(@admin_root, @actor)
    grant_admin!(@root, @actor)
    Current.actor = @actor
    sign_in @actor
  end

  teardown do
    Current.actor = nil
  end

  test "a feature stays off the page and a hero stays out of a grid" do
    page_recording = create_page!(parent_recording: @root, title: "Rules", actor: @actor)
    grid = add_section!(
      page_recording: page_recording,
      section_type: "feature_grid",
      content: { title: "What you get" },
      actor: @actor
    )

    on_page = RecordingStudioPages::Services::AddSection.call(
      page_recording: page_recording,
      section_type: "feature",
      content: { title: "Pages" },
      actor: @actor
    )
    under_grid = RecordingStudioPages::Services::AddSection.call(
      parent_recording: grid,
      section_type: "hero",
      content: { title: "Nope" },
      actor: @actor
    )
    feature = add_section!(
      parent_recording: grid,
      section_type: "feature",
      content: { title: "Pages", body: "A stack." },
      actor: @actor
    )
    nested = RecordingStudioPages::Services::AddSection.call(
      parent_recording: feature,
      section_type: "feature",
      content: { title: "Too deep" },
      actor: @actor
    )

    assert on_page.failure?
    assert_match(/parent section/i, on_page.error.to_s)
    assert under_grid.failure?
    assert_match(/does not belong/i, under_grid.error.to_s)
    assert nested.failure?
    page_types = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
                                                  .map { |recording| recording.recordable.section_type }
    assert_equal ["feature_grid"], page_types
    assert_equal ["Pages"], child_titles(grid)
  end

  test "upgrade turns saved feature and logo items into child sections" do
    page_recording = create_page!(parent_recording: @root, title: "Legacy", actor: @actor)
    grid = add_section!(
      page_recording: page_recording,
      section_type: "feature_grid",
      content: { title: "What you get" },
      actor: @actor
    )
    cloud = add_section!(
      page_recording: page_recording,
      section_type: "logo_cloud",
      content: { title: "Names on the door" },
      actor: @actor
    )
    logo = attach_image!(parent_recording: cloud, actor: @actor, filename: "mark.png")
    store_legacy_content(
      grid,
      "title" => "What you get",
      "body" => "Still here.",
      "items" => [
        { "title" => "Pages", "body" => "A stack you can reorder." },
        { "title" => "", "body" => "" }
      ]
    )
    store_legacy_content(
      cloud,
      "title" => "Names on the door",
      "items" => [{ "name" => "House lights", "url" => "https://example.com", "image" => logo.id }]
    )
    publish_page!(page_recording, slug: "legacy-#{SecureRandom.hex(4)}", actor: @actor)

    upgraded = RecordingStudioPages::Services::UpgradeNestedSections.call(actor: @actor).value!

    assert_equal 2, upgraded
    assert_equal ["Pages"], child_titles(grid.reload)
    assert_equal "A stack you can reorder.", child_recordings(grid).first.recordable.content["body"]
    refute grid.recordable.content.key?("items")
    assert_equal "Still here.", grid.recordable.content["body"]
    logos = child_recordings(cloud.reload)
    assert_equal ["House lights"], logos.map { |recording| recording.recordable.content["name"] }
    assert_equal "https://example.com", logos.first.recordable.content["url"]
    copied_id = logos.first.recordable.content["image"]
    assert_not_equal logo.id, copied_id
    copied = RecordingStudio::Recording.find(copied_id)
    assert_equal logos.first.id, copied.parent_recording_id
    refute cloud.recordable.content.key?("items")

    assert_no_difference -> { RecordingStudio::Recording.count } do
      assert_equal 0, RecordingStudioPages::Services::UpgradeNestedSections.call(actor: @actor).value!
    end
  end

  test "a published page renders enabled child sections after upgrade" do
    isolate_public_homepage!
    page_recording = create_page!(parent_recording: @root, title: "Live grid", homepage: true, actor: @actor)
    grid = add_section!(
      page_recording: page_recording,
      section_type: "feature_grid",
      content: { title: "What you get" },
      actor: @actor
    )
    store_legacy_content(
      grid,
      "title" => "What you get",
      "items" => [
        { "title" => "Pages", "body" => "A stack you can reorder." },
        { "title" => "Hidden", "body" => "Stay off the page." }
      ]
    )
    RecordingStudioPages::Services::UpgradeNestedSections.call(actor: @actor).value!
    hidden = child_recordings(grid.reload).find { |recording| recording.recordable.content["title"] == "Hidden" }
    RecordingStudioPages::Services::ToggleSection.call(
      section_recording: hidden,
      enabled: false,
      actor: @actor
    ).value!
    publish_page!(page_recording, slug: "live-grid-#{SecureRandom.hex(4)}", actor: @actor)

    get site_path

    assert_response :success
    assert_includes response.body, "What you get"
    assert_includes response.body, "Pages"
    assert_includes response.body, "A stack you can reorder."
    refute_includes response.body, "Stay off the page."
  end

  test "copying a grid copies its features and their pictures" do
    page_recording = create_page!(parent_recording: @root, title: "Copies", actor: @actor)
    grid = add_section!(
      page_recording: page_recording,
      section_type: "feature_grid",
      content: { title: "What you get" },
      actor: @actor
    )
    feature = add_section!(
      parent_recording: grid,
      section_type: "feature",
      content: { title: "Pages", body: "A stack." },
      actor: @actor
    )
    photo = attach_image!(parent_recording: feature, actor: @actor, filename: "feature.png")
    RecordingStudioPages::Services::ReviseSection.call(
      section_recording: feature,
      content: feature.recordable.content.merge("image" => photo.id),
      actor: @actor
    ).value!

    copy = RecordingStudioPages::Services::DuplicateSection.call(
      section_recording: grid,
      actor: @actor
    ).value!

    copied_features = child_recordings(copy)
    assert_equal ["Pages"], copied_features.map { |recording| recording.recordable.content["title"] }
    assert_not_equal feature.id, copied_features.first.id
    copied_photo_id = copied_features.first.recordable.content["image"]
    assert_not_equal photo.id, copied_photo_id
    assert_equal copied_features.first.id, RecordingStudio::Recording.find(copied_photo_id).parent_recording_id
    assert_equal [grid.id, copy.id], RecordingStudioPages::Composition.section_recordings_for(page_recording.reload).map(&:id)
  end

  test "removing a grid removes its features" do
    page_recording = create_page!(parent_recording: @root, title: "Trash", actor: @actor)
    grid = add_section!(
      page_recording: page_recording,
      section_type: "feature_grid",
      content: { title: "What you get" },
      actor: @actor
    )
    feature = add_section!(
      parent_recording: grid,
      section_type: "feature",
      content: { title: "Pages" },
      actor: @actor
    )

    RecordingStudioPages::Services::RemoveSection.call(section_recording: grid, actor: @actor).value!

    assert grid.reload.trashed_at
    assert feature.reload.trashed_at
    assert_empty RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_empty RecordingStudioPages::Composition.child_section_recordings_for(grid)
  end

  test "staff can add, reorder, and remove a feature from the grid" do
    page_recording = create_page!(parent_recording: @root, title: "Editor", actor: @actor)
    grid = add_section!(
      page_recording: page_recording,
      section_type: "feature_grid",
      content: { title: "What you get" },
      actor: @actor
    )
    first = add_section!(
      parent_recording: grid,
      section_type: "feature",
      content: { title: "Pages", body: "A stack." },
      actor: @actor
    )
    second = add_section!(
      parent_recording: grid,
      section_type: "feature",
      content: { title: "Pieces", body: "Each has a job." },
      actor: @actor
    )

    get recording_studio_pages.admin_page_path(page_recording)
    assert_response :success
    assert_select "input[name='section[section_type]'][value='feature']", count: 0
    assert_select "input[name='section[section_type]'][value='feature_grid']"

    get recording_studio_pages.edit_admin_page_section_path(page_id: page_recording.id, id: grid.id)
    assert_response :success
    assert_select "input[name='section[section_type]'][value='feature']"
    assert_includes response.body, "Pages"
    refute_includes response.body, "Items"

    post recording_studio_pages.admin_page_sections_path(page_recording), params: {
      section: { section_type: "feature", parent_section_id: grid.id }
    }
    assert_redirected_to recording_studio_pages.edit_admin_page_section_path(page_id: page_recording.id, id: grid.id)
    follow_redirect!
    assert_includes response.body, "Feature added."
    assert_equal 3, child_recordings(grid.reload).length

    patch recording_studio_pages.reorder_admin_page_sections_path(page_recording),
          params: { moving_recording_id: second.id, target_position: 1 },
          headers: { "Accept" => "application/json" }
    assert_response :success
    assert_equal [second.id, first.id], child_recordings(grid.reload).first(2).map(&:id)

    delete recording_studio_pages.admin_page_section_path(page_recording, first)
    assert_redirected_to recording_studio_pages.edit_admin_page_section_path(page_id: page_recording.id, id: grid.id)
    assert first.reload.trashed_at
    refute_includes child_recordings(grid.reload).map(&:id), first.id
  end

  private

  def child_recordings(section_recording)
    RecordingStudioPages::Composition.child_section_recordings_for(section_recording)
  end

  def store_legacy_content(section_recording, content)
    RecordingStudioPages::Section.where(id: section_recording.recordable_id).update_all(content: content)
    section_recording.reload
  end

  def child_titles(section_recording)
    child_recordings(section_recording).map { |recording| recording.recordable.content["title"] }
  end
end
