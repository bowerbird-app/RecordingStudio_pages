# frozen_string_literal: true

require "test_helper"

class PageBuilderImagesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @actor = create_actor!("images@example.com")
    @root = create_workspace_root!("Images Workspace #{SecureRandom.hex(4)}")
    @admin_root = create_admin_root!
    grant_admin!(@admin_root, @actor)
    grant_admin!(@root, @actor)
    Current.actor = @actor
    sign_in @actor
  end

  teardown do
    Current.actor = nil
  end

  test "the hero editor offers choose image instead of an image url field" do
    page_recording = create_page!(parent_recording: @root, title: "Photo door", actor: @actor)
    section = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Lights up", image_url: "/images/hero-tonight.jpg" },
      settings: { variant: "fullscreen_image" },
      actor: @actor
    )

    get recording_studio_pages.edit_admin_page_section_path(page_id: page_recording.id, id: section.id)

    assert_response :success
    assert_includes response.body, "Choose image"
    assert_includes response.body, "recording-studio-attachable--attachment-image-picker"
    assert_includes response.body, recording_studio_attachable.recording_attachment_picker_path(section)
    assert_includes response.body, "hero-tonight.jpg"
    refute_includes response.body, "Image url"
    assert_equal "/images/hero-tonight.jpg", section.reload.recordable.content["image"]
  end

  test "staff can save an attached image on a section" do
    page_recording = create_page!(parent_recording: @root, title: "Attach me", actor: @actor)
    section = add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: { title: "Poster" },
      actor: @actor
    )
    attachment = attach_image!(parent_recording: section, actor: @actor)

    patch recording_studio_pages.admin_page_section_path(page_id: page_recording.id, id: section.id),
          params: {
            section: {
              content: {
                title: "Poster",
                image: attachment.id
              }
            }
          }

    assert_redirected_to recording_studio_pages.admin_page_path(id: page_recording.id)
    saved = section.reload.recordable.content
    assert_equal attachment.id, saved["image"]
    refute saved.key?("image_url")

    rendered = RecordingStudioPages::Renderer.section(section.reload, context: self)
    assert_includes rendered.content["image"].to_s, "rails/active_storage"
    refute_equal attachment.id, rendered.content["image"]
  end

  test "copying a section copies its image and rewrites the saved id" do
    page_recording = create_page!(parent_recording: @root, title: "Copy photo", actor: @actor)
    section = add_section!(
      page_recording: page_recording,
      section_type: "image_text",
      content: { title: "Side photo" },
      actor: @actor
    )
    attachment = attach_image!(parent_recording: section, actor: @actor, filename: "side.png")
    RecordingStudioPages::Services::ReviseSection.call(
      section_recording: section,
      content: { title: "Side photo", image: attachment.id },
      actor: @actor
    ).value!

    post recording_studio_pages.duplicate_admin_page_section_path(page_recording, section)
    follow_redirect!
    assert_includes response.body, "Section copied."

    copy = RecordingStudioPages::Composition.section_recordings_for(page_recording.reload).last
    refute_equal section.id, copy.id
    copy_image_id = copy.recordable.content["image"]
    refute_equal attachment.id, copy_image_id
    copy_attachment = RecordingStudio::Recording.find(copy_image_id)
    assert_equal "RecordingStudioAttachable::Attachment", copy_attachment.recordable_type
    assert_equal copy.id, copy_attachment.parent_recording_id
    assert copy_attachment.recordable.file.attached?
  end

  test "public pages still render a legacy image url" do
    isolate_public_homepage!
    page_recording = create_page!(parent_recording: @root, title: "Legacy lights", actor: @actor)
    add_section!(
      page_recording: page_recording,
      section_type: "hero",
      content: {
        title: "The floor is already warm",
        image_url: "/images/hero-tonight.jpg"
      },
      settings: { variant: "fullscreen_image" },
      actor: @actor
    )
    publishable = publish_page!(page_recording, slug: "legacy-lights", actor: @actor)

    get "/pages/#{publishable.id}/legacy-lights"

    assert_response :success
    assert_includes response.body, "hero-tonight.jpg"
    assert_includes response.body, "background-image:"
  end
end
