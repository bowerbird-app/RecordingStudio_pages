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
    RecordingStudioPages::Services::ApplyTemplate.call(
      page_recording: homepage_recording,
      template_key: "marketing_home",
      actor: user
    ).value!
  end

  publish_page.call(homepage_recording, "home", user)

  logo_recording = RecordingStudioPages::Composition.section_recordings_for(homepage_recording).find do |recording|
    recording.recordable.section_type == "logo_cloud"
  end
  if logo_recording && Array(logo_recording.recordable.content["items"]).empty?
    RecordingStudioPages::Services::ReviseSection.call(
      section_recording: logo_recording,
      content: logo_recording.recordable.content.merge(
        "items" => [
          { "name" => "Recording Studio" },
          { "name" => "Publishable" },
          { "name" => "Admin" }
        ]
      ),
      actor: user
    ).value!
  end

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
      content: { title: "About this studio", body: "A page is a recording. Sections hang under it." },
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
