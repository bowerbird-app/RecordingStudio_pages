# frozen_string_literal: true

require "test_helper"

class PageBuilderPublicTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @actor = create_actor!("public-pages@example.com")
    Current.actor = @actor
    @root = create_workspace_root!("Public Workspace #{SecureRandom.hex(4)}")
    grant_admin!(@root, @actor)
    isolate_public_homepage!
  end

  teardown do
    Current.actor = nil
  end

  test "dummy host names the rounded Flatpack theme" do
    assert_equal :rounded, FlatPack.configuration.default_theme
    assert_equal "rounded", RecordingStudioPages.theme
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
      content: { title: "Off", body: "disabled_section_copy" },
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
    assert_includes response.body, "text-4xl"
    refute_includes response.body, "disabled_section_copy"
    assert_includes response.body, 'data-theme="rounded"'
    assert_includes response.body, "max-w-6xl"
    refute_includes response.body, "max-w-md"
    assert_includes response.body, "flat_pack/application"
    refute_includes response.body, "data-recording-studio-default-layout"
  end

  test "section variants change public markup" do
    page_recording = create_page!(parent_recording: @root, title: "Variant home", homepage: true, actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "rich_text",
      content: { title: "Narrow notes", body: "Keep this column tight." },
      settings: { variant: "narrow" },
      actor: @actor
    )
    add_section!(
      page_recording: page_recording,
      section_type: "call_to_action",
      content: { title: "Banner next", body: "A full-width ask." },
      settings: { variant: "banner" },
      actor: @actor
    )
    publish_page!(page_recording, slug: "variant-home", actor: @actor)

    get root_path

    assert_response :success
    assert_includes response.body, "Narrow notes"
    assert_includes response.body, "max-w-prose"
    assert_includes response.body, "Banner next"
    assert_includes response.body, "bg-[var(--surface-muted-background-color)]"
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
    assert_includes response.body, "max-w-6xl"
    refute_includes response.body, "max-w-md"
    refute_includes response.body, "data-recording-studio-default-layout"
    assert_includes response.body, 'data-theme="rounded"'
  end

  test "public pages use the host Flatpack theme" do
    original = FlatPack.configuration.default_theme
    FlatPack.configuration.default_theme = :featured_in
    page_recording = create_page!(parent_recording: @root, title: "Themed home", homepage: true, actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Host theme" },
      actor: @actor
    )
    publish_page!(page_recording, slug: "themed-home", actor: @actor)

    get root_path

    assert_response :success
    assert_includes response.body, 'data-theme="featured-in"'
    refute_includes response.body, 'data-theme="rounded"'
    assert_includes response.body, "Host theme"
  ensure
    FlatPack.configuration.default_theme = original
  end

  test "a published page can be only a fullscreen hero" do
    page_recording = create_page!(parent_recording: @root, title: "Tonight", actor: @actor)
    RecordingStudioPages::Services::ApplyTemplate.call(
      page_recording: page_recording,
      template_key: "full_bleed_hero",
      actor: @actor
    ).value!
    heroes = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
    assert_equal 1, heroes.size
    hero = heroes.first
    RecordingStudioPages::Services::ReviseSection.call(
      section_recording: hero,
      content: hero.recordable.content.merge("image_url" => "/images/hero-tonight.jpg"),
      actor: @actor
    ).value!
    publishable = publish_page!(page_recording, slug: "tonight", actor: @actor)

    get "/pages/#{publishable.id}/tonight"

    assert_response :success
    assert_includes response.body, "The floor is already warm"
    assert_includes response.body, "Doors at eight"
    assert_includes response.body, "Take a seat"
    assert_includes response.body, "hero-tonight.jpg"
    assert_includes response.body, "background-image:"
    assert_includes response.body, "bg-black/60"
    refute_includes response.body, "What this gem owns"
    refute_includes response.body, "max-w-6xl"
    refute_includes response.body, "data-recording-studio-default-layout"
    assert_includes response.body, "h-dvh"
    assert_includes response.body, "h-full"
    assert_includes response.body, "bg-black"
    refute_includes response.body, "h-screen"
    types = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload)
                                             .map { |recording| recording.recordable.section_type }
    assert_equal ["hero"], types
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

  test "a hero can render a host social login CTA" do
    page_recording = create_page!(parent_recording: @root, title: "Join", actor: @actor)
    RecordingStudioPages::Services::ApplyTemplate.call(
      page_recording: page_recording,
      template_key: "join",
      actor: @actor
    ).value!
    publishable = publish_page!(page_recording, slug: "join-us", actor: @actor)

    get "/pages/#{publishable.id}/join-us"

    assert_response :success
    assert_includes response.body, "Come as you are"
    assert_includes response.body, "Continue with Google"
    assert_includes response.body, "Continue with Apple"
    assert_includes response.body, "/users/sign_in"
    refute_includes response.body, "Take a seat"
  end

  test "a hero can render a host URL field CTA" do
    page_recording = create_page!(parent_recording: @root, title: "Start", actor: @actor)
    RecordingStudioPages::Services::ApplyTemplate.call(
      page_recording: page_recording,
      template_key: "start_from_url",
      actor: @actor
    ).value!
    publishable = publish_page!(page_recording, slug: "start-here", actor: @actor)

    get "/pages/#{publishable.id}/start-here"

    assert_response :success
    assert_includes response.body, "Got a link?"
    assert_includes response.body, 'action="/start"'
    assert_includes response.body, "Open it"
    assert_includes response.body, 'name="url"'
  end

  test "a saved primary_action hero still renders a button" do
    page_recording = create_page!(parent_recording: @root, title: "Legacy", actor: @actor)
    hero = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Old door" },
      actor: @actor
    )
    hero.root_recording.revise(hero, actor: @actor) do |section|
      section.content = {
        "title" => "Old door",
        "primary_action" => { "text" => "Walk in", "url" => "/users/sign_in" }
      }
    end
    rendered = RecordingStudioPages::Renderer.call(page_recording.reload)
    publishable = publish_page!(page_recording, slug: "legacy-hero", actor: @actor)

    get "/pages/#{publishable.id}/legacy-hero"

    assert_equal "button", rendered.first.content.dig("cta", "type")
    assert_equal "Walk in", rendered.first.content.dig("cta", "text")
    assert_response :success
    assert_includes response.body, "Old door"
    assert_includes response.body, "Walk in"
    assert_includes response.body, "/users/sign_in"
  end

  test "revising a legacy hero persists the cta shape" do
    page_recording = create_page!(parent_recording: @root, title: "Upgrade", actor: @actor)
    hero = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Old door" },
      actor: @actor
    )
    hero.root_recording.revise(hero, actor: @actor) do |section|
      section.content = {
        "title" => "Old door",
        "primary_action" => { "text" => "Walk in", "url" => "/users/sign_in" }
      }
    end

    RecordingStudioPages::Services::ReviseSection.call(
      section_recording: hero.reload,
      content: hero.recordable.content.merge("title" => "Old door"),
      actor: @actor
    ).value!

    saved = hero.reload.recordable.content
    assert_equal "button", saved.dig("cta", "type")
    assert_equal "Walk in", saved.dig("cta", "text")
    refute saved.key?("primary_action")
  end

  test "an unknown CTA type skips the slot and keeps the hero" do
    page_recording = create_page!(parent_recording: @root, title: "Mystery", actor: @actor)
    hero = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Still here", cta: { type: "button", text: "Stay", url: "/users/sign_in" } },
      actor: @actor
    )
    hero.root_recording.revise(hero, actor: @actor) do |section|
      section.content = {
        "title" => "Still here",
        "cta" => { "type" => "missing_widget", "text" => "Hidden ask" }
      }
    end
    publishable = publish_page!(page_recording, slug: "mystery-hero", actor: @actor)

    get "/pages/#{publishable.id}/mystery-hero"

    assert_response :success
    assert_includes response.body, "Still here"
    refute_includes response.body, "Hidden ask"
  end
end
