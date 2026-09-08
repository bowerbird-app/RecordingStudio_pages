# frozen_string_literal: true

find_or_record_child = lambda do |recordable, root_recording, parent_recording|
  RecordingStudio::Recording.find_by(
    root_recording: root_recording,
    parent_recording: parent_recording,
    recordable: recordable,
    trashed_at: nil
  ) || RecordingStudio.record!(
    action: "created",
    recordable: recordable,
    root_recording: root_recording,
    parent_recording: parent_recording
  ).recording
end

grant_admin_access = lambda do |recording, actor|
  next if RecordingStudioAccessible.role_for(actor: actor, recording: recording) == :admin

  RecordingStudioAccessible::AccessCreationContext.allow do
    root_recording = RecordingStudio.root_recording_or_self(recording)
    root_recording.record(RecordingStudio::Access, parent_recording: recording) do |access|
      access.actor = actor
      access.role = :admin
    end
  end
end

find_page_recording = lambda do |title|
  RecordingStudio::Recording.where(recordable_type: "RecordingStudioPages::Page", trashed_at: nil)
                            .includes(:recordable)
                            .find { |recording| recording.recordable&.title == title }
end

publish_page = lambda do |page_recording, slug, actor|
  RecordingStudioPublishable::Services::Publishables::Update.call(
    parent_recording: page_recording,
    attributes: { slug: slug, status: "published" },
    actor: actor
  ).value!
end

restore_template_sections = lambda do |page_recording, template_key, actor|
  template = RecordingStudioPages.template(template_key)
  expected_types = template.sections.map { |entry| entry.fetch("type").to_s }
  hero_entry = template.sections.find { |entry| entry.fetch("type").to_s == "hero" }
  expected_hero_title = (hero_entry&.fetch("content") || {}).to_h.stringify_keys["title"]
  sections = RecordingStudioPages::Composition.section_recordings_for(page_recording)
  types = sections.map { |recording| recording.recordable.section_type }
  hero_title = sections.find { |recording| recording.recordable.section_type == "hero" }
                       &.recordable&.content&.[]("title")
  return if types == expected_types && hero_title == expected_hero_title

  sections.each do |recording|
    RecordingStudioPages::Services::RemoveSection.call(section_recording: recording, actor: actor).value!
  end
  RecordingStudioPages::Services::ApplyTemplate.call(
    page_recording: page_recording,
    template_key: template_key,
    actor: actor
  ).value!
end

user = User.find_or_create_by!(email: "admin@admin.com") do |record|
  record.password = "Password"
  record.password_confirmation = "Password"
end

workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
accessible_workspace = Workspace.find_or_create_by!(name: "Client Workspace")
private_workspace = Workspace.find_or_create_by!(name: "Private Workspace")
folder = Folder.find_or_create_by!(name: "Product Docs")
admin_root = AdminRoot.find_or_create_by!(name: "Admin")

previous_actor = Current.actor
Current.actor = user

begin
  root_recording = RecordingStudio.root_recording_for(workspace)
  accessible_root_recording = RecordingStudio.root_recording_for(accessible_workspace)
  private_root_recording = RecordingStudio.root_recording_for(private_workspace)
  admin_root_recording = RecordingStudio.root_recording_for(admin_root)

  folder_recording = find_or_record_child.call(folder, root_recording, root_recording)

  [root_recording, accessible_root_recording, private_root_recording, admin_root_recording].each do |recording|
    grant_admin_access.call(recording, user)
  end

  homepage_recording = find_page_recording.call("Home")

  unless homepage_recording
    homepage_recording = RecordingStudioPages::Services::CreatePage.call(
      parent_recording: root_recording,
      title: "Home",
      homepage: true,
      actor: user
    ).value!
  end

  restore_template_sections.call(homepage_recording, "marketing_home", user)
  publish_page.call(homepage_recording, "home", user)

  about_recording = find_page_recording.call("About")

  unless about_recording
    about_recording = RecordingStudioPages::Services::CreatePage.call(
      parent_recording: folder_recording,
      title: "About",
      homepage: false,
      actor: user
    ).value!
    RecordingStudioPages::Services::AddSection.call(
      page_recording: about_recording,
      section_type: "rich_text",
      content: { title: "About this studio", body: "This page sits with the rest of the site. Pieces stack underneath." },
      actor: user
    ).value!
  end

  publish_page.call(about_recording, "about", user)

  tonight_recording = find_page_recording.call("Tonight")

  unless tonight_recording
    tonight_recording = RecordingStudioPages::Services::CreatePage.call(
      parent_recording: root_recording,
      title: "Tonight",
      homepage: false,
      actor: user
    ).value!
    RecordingStudioPages::Services::ApplyTemplate.call(
      page_recording: tonight_recording,
      template_key: "full_bleed_hero",
      actor: user
    ).value!
  end

  hero_recording = RecordingStudioPages::Composition.section_recordings_for(tonight_recording).find do |recording|
    recording.recordable.section_type == "hero"
  end
  if hero_recording && hero_recording.recordable.content["image_url"].blank?
    RecordingStudioPages::Services::ReviseSection.call(
      section_recording: hero_recording,
      content: hero_recording.recordable.content.merge("image_url" => "/images/hero-tonight.jpg"),
      settings: hero_recording.recordable.settings.merge("variant" => "fullscreen_image"),
      actor: user
    ).value!
  end

  publish_page.call(tonight_recording, "tonight", user)

  puts "Seeded: admin@admin.com / Password"
  puts "Seeded: Workspace '#{workspace.name}' with homepage '#{homepage_recording.recordable.title}'"
  puts "Seeded: Admin root '#{admin_root.name}'"
ensure
  Current.actor = previous_actor
end
