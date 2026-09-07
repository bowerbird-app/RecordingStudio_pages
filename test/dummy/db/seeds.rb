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

  homepage_recordable = RecordingStudioPages::Page.find_by(title: "Home")
  homepage_recording = homepage_recordable && RecordingStudio::Recording.find_by(
    recordable: homepage_recordable,
    trashed_at: nil
  )

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

  about_recordable = RecordingStudioPages::Page.find_by(title: "About")
  about_recording = about_recordable && RecordingStudio::Recording.find_by(
    recordable: about_recordable,
    trashed_at: nil
  )

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

  puts "Seeded: admin@admin.com / Password"
  puts "Seeded: Workspace '#{workspace.name}' with homepage '#{homepage_recording.recordable.title}'"
  puts "Seeded: Admin root '#{admin_root.name}'"
ensure
  Current.actor = previous_actor
end
