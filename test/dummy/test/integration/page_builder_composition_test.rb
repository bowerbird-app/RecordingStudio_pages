# frozen_string_literal: true

require "test_helper"

class PageBuilderCompositionTest < ActiveSupport::TestCase
  setup do
    @actor = create_actor!("composition@example.com")
    Current.actor = @actor
    @root = create_workspace_root!("Composition Workspace #{SecureRandom.hex(4)}")
    grant_admin!(@root, @actor)
  end

  teardown do
    Current.actor = nil
  end

  test "page and section are recordings and the page contains ordered child sections" do
    page_recording = create_page!(parent_recording: @root, title: "Landing", actor: @actor)
    hero = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Hello" },
      actor: @actor
    )
    rich_text = add_section!(
      page_recording: page_recording,
      section_type: "rich_text",
      content: { title: "Body", body: "Notes" },
      actor: @actor
    )

    children = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)

    assert_equal "RecordingStudioPages::Page", page_recording.recordable_type
    assert_equal "RecordingStudioPages::Section", hero.recordable_type
    assert_equal [hero.id, rich_text.id], children.map(&:id)
    assert RecordingStudio.validate_recordable_declarations!
  end

  test "the same section recordable backs many section types without a new table" do
    page_recording = create_page!(parent_recording: @root, title: "Mixed", actor: @actor)
    hero = add_section!(page_recording: page_recording, section_type: "hero", content: { title: "Hero" }, actor: @actor)
    cta = add_section!(
      page_recording: page_recording,
      section_type: "call_to_action",
      content: { title: "Go" },
      actor: @actor
    )

    assert_equal "RecordingStudioPages::Section", hero.recordable_type
    assert_equal "RecordingStudioPages::Section", cta.recordable_type
    assert_equal "hero", hero.recordable.section_type
    assert_equal "call_to_action", cta.recordable.section_type
    assert ActiveRecord::Base.connection.table_exists?(:recording_studio_pages_sections)
    refute ActiveRecord::Base.connection.table_exists?(:recording_studio_pages_hero_sections)
  end

  test "content and settings persist and disabled sections are skipped on render" do
    page_recording = create_page!(parent_recording: @root, title: "Render", actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Visible" },
      actor: @actor
    )
    hidden = add_section!(
      page_recording: page_recording,
      section_type: "rich_text",
      content: { title: "Hidden" },
      enabled: false,
      actor: @actor
    )

    rendered = RecordingStudioPages::Renderer.call(page_recording.reload)

    assert_equal ["Visible"], rendered.map { |item| item.content["title"] }
    refute hidden.recordable.enabled?
  end

  test "unknown section types fail safe and keep their data" do
    page_recording = create_page!(parent_recording: @root, title: "Unknown", actor: @actor)
    known = add_section!(page_recording: page_recording, section_type: "hero", content: { title: "Known" }, actor: @actor)
    unknown = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Later" },
      actor: @actor
    )
    unknown.root_recording.revise(unknown, actor: @actor) do |section|
      section.section_type = "from_the_future"
      section.content = { "title" => "Keep me" }
    end

    rendered = RecordingStudioPages::Renderer.call(page_recording.reload)
    leftover = RecordingStudioPages::Section.find(unknown.reload.recordable_id)

    assert_equal [known.id], rendered.map { |item| item.recording.id }
    assert_equal "from_the_future", leftover.section_type
    assert_equal "Keep me", leftover.content["title"]
  end

  test "templates create independent section recordings" do
    first = create_page!(parent_recording: @root, title: "First", actor: @actor)
    second = create_page!(parent_recording: @root, title: "Second", actor: @actor)
    RecordingStudioPages::Services::ApplyTemplate.call(
      page_recording: first,
      template_key: "marketing_home",
      actor: @actor
    ).value!
    RecordingStudioPages::Services::ApplyTemplate.call(
      page_recording: second,
      template_key: "marketing_home",
      actor: @actor
    ).value!

    first_ids = RecordingStudioPages::Composition.section_recordings_for(first.reload).map(&:id)
    second_ids = RecordingStudioPages::Composition.section_recordings_for(second.reload).map(&:id)

    refute_empty first_ids
    refute_empty second_ids
    assert_empty first_ids & second_ids
  end

  test "setting a second homepage clears the first" do
    first = create_page!(parent_recording: @root, title: "Home A", homepage: true, actor: @actor)
    second = create_page!(parent_recording: @root, title: "Home B", homepage: true, actor: @actor)

    assert_not first.reload.recordable.homepage?
    assert second.reload.recordable.homepage?
    assert_equal second.id, RecordingStudioPages::Composition.homepage_recording(root_recording: @root).id
  end

  test "public homepage lookup prefers a published page" do
    isolate_public_homepage!
    draft_root = create_workspace_root!("Draft Home Workspace #{SecureRandom.hex(4)}")
    live_root = create_workspace_root!("Live Home Workspace #{SecureRandom.hex(4)}")
    grant_admin!(draft_root, @actor)
    grant_admin!(live_root, @actor)
    draft = create_page!(parent_recording: draft_root, title: "Draft site home", homepage: true, actor: @actor)
    live = create_page!(parent_recording: live_root, title: "Live site home", homepage: true, actor: @actor)
    publish_page!(live, slug: "live-site-home", actor: @actor)

    assert_equal live.id, RecordingStudioPages::Composition.homepage_recording.id
    assert_not_equal draft.id, RecordingStudioPages::Composition.homepage_recording.id
  end

  test "data-backed sections resolve live records without copying them into content" do
    RecordingStudioPages.register_section(
      key: :recent_workspaces,
      name: "Recent workspaces",
      category: "data",
      component: "RecordingStudioPages::Sections::RichTextComponent",
      fields: { title: :string },
      data: ->(_recording, _content, _settings, _context) { Workspace.order(:name).limit(2).to_a }
    )
    page_recording = create_page!(parent_recording: @root, title: "Data", actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "recent_workspaces",
      content: { title: "Live workspaces" },
      actor: @actor
    )

    rendered = RecordingStudioPages::Renderer.call(page_recording.reload)

    assert_equal "recent_workspaces", rendered.first.recording.recordable.section_type
    assert_empty rendered.first.recording.recordable.content["workspaces"] || []
    assert rendered.first.data.is_a?(Array)
    refute_empty rendered.first.data
    assert rendered.first.data.all? { |record| record.is_a?(Workspace) }
  ensure
    RecordingStudioPages.reset!
    RecordingStudioPages::BuiltIns.register!
  end

  test "duplicating a section creates another generic section recording" do
    page_recording = create_page!(parent_recording: @root, title: "Copy", actor: @actor)
    original = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Original hero" },
      settings: { variant: "centered" },
      actor: @actor
    )

    copy = RecordingStudioPages::Services::DuplicateSection.call(
      section_recording: original,
      actor: @actor
    ).value!

    sections = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal 2, sections.length
    assert_equal "hero", copy.recordable.section_type
    assert_equal "Original hero", copy.recordable.content["title"]
    assert_equal "centered", copy.recordable.settings["variant"]
    assert_not_equal original.id, copy.id
    assert_not_equal original.recordable_id, copy.recordable_id
    assert_equal original.parent_recording_id, copy.parent_recording_id
    assert_equal sections.last.id, copy.id
    assert copy.events.exists?(action: "duplicated")
  end

  test "duplicating a section requires edit access" do
    page_recording = create_page!(parent_recording: @root, title: "Locked copy", actor: @actor)
    original = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Stay put" },
      actor: @actor
    )
    stranger = create_actor!("copy-stranger@example.com")

    result = RecordingStudioPages::Services::DuplicateSection.call(
      section_recording: original,
      actor: stranger
    )

    assert result.failure?
    assert_match(/access/i, result.error.to_s)
    assert_equal 1, RecordingStudioPages::Composition.section_recordings_for(page_recording.reload).length
  end

  test "moving a section uses Recording Studio Orderable position" do
    page_recording = create_page!(parent_recording: @root, title: "Order", actor: @actor)
    first = add_section!(page_recording: page_recording, section_type: "hero", content: { title: "First" }, actor: @actor)
    second = add_section!(
      page_recording: page_recording,
      section_type: "rich_text",
      content: { title: "Second" },
      actor: @actor
    )

    RecordingStudioPages::Services::MoveSection.call(
      page_recording: page_recording,
      section_recording: second,
      to_index: 0,
      actor: @actor
    ).value!

    ordered = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal [second.id, first.id], ordered.map(&:id)
  end

  test "page recordable does not store SEO fields" do
    page_recording = create_page!(parent_recording: @root, title: "SEO", actor: @actor)
    columns = page_recording.recordable.class.column_names

    refute_includes columns, "slug"
    refute_includes columns, "seo_title"
    refute_includes columns, "published"
    refute_includes columns, "status"
  end
end
