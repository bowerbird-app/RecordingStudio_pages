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

  result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
  next if result.success?

  manager = User.where.not(id: actor.id).first
  result = RecordingStudioAccessible.grant_access(
    recording: recording,
    actor: actor,
    role: :admin,
    manager_actor: manager
  ) if manager

  raise result.error if result.failure?
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
  expected_hero = (hero_entry&.fetch("content") || {}).to_h.stringify_keys
  expected_hero_title = expected_hero["title"]
  expected_cta_type = expected_hero.dig("cta", "type")
  expected_image_url = expected_hero["image_url"]
  expected_variant = (hero_entry&.fetch("settings") || {}).to_h.stringify_keys["variant"]
  sections = RecordingStudioPages::Composition.section_recordings_for(page_recording)
  types = sections.map { |recording| recording.recordable.section_type }
  hero = sections.find { |recording| recording.recordable.section_type == "hero" }&.recordable
  hero_title = hero&.content&.[]("title")
  hero_cta_type = hero&.content&.dig("cta", "type")
  hero_image_url = hero&.content&.[]("image_url")
  hero_variant = hero&.settings&.[]("variant")
  legacy_cta = hero&.content&.[]("primary_action").present? && hero_cta_type.blank?
  cta_drift = expected_cta_type.present? && hero_cta_type != expected_cta_type
  image_drift = expected_image_url.present? && hero_image_url != expected_image_url
  variant_drift = expected_variant.present? && hero_variant != expected_variant
  return if types == expected_types && hero_title == expected_hero_title && !legacy_cta && !cta_drift &&
            !image_drift && !variant_drift

  sections.each do |recording|
    RecordingStudioPages::Services::RemoveSection.call(section_recording: recording, actor: actor).value!
  end
  RecordingStudioPages::Services::ApplyTemplate.call(
    page_recording: page_recording,
    template_key: template_key,
    actor: actor
  ).value!
end

user = User.find_or_initialize_by(email: "admin@admin.com")
if user.new_record?
  user.password = "Password"
  user.password_confirmation = "Password"
  user.save!
end

if RecordingStudioUser.profile_for(user).nil?
  RecordingStudioUser.record_profile!(
    user,
    first_name: "Ada",
    last_name: "Admin",
    time_zone: "UTC",
    actor: user
  )
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
  end

  restore_template_sections.call(tonight_recording, "full_bleed_hero", user)

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

  join_recording = find_page_recording.call("Join")
  unless join_recording
    join_recording = RecordingStudioPages::Services::CreatePage.call(
      parent_recording: root_recording,
      title: "Join",
      homepage: false,
      actor: user
    ).value!
  end
  restore_template_sections.call(join_recording, "join", user)
  publish_page.call(join_recording, "join", user)

  walk_in_recording = find_page_recording.call("Walk in")
  unless walk_in_recording
    walk_in_recording = RecordingStudioPages::Services::CreatePage.call(
      parent_recording: root_recording,
      title: "Walk in",
      homepage: false,
      actor: user
    ).value!
  end
  restore_template_sections.call(walk_in_recording, "walk_in", user)
  publish_page.call(walk_in_recording, "walk-in", user)

  start_recording = find_page_recording.call("Start from a URL")
  unless start_recording
    start_recording = RecordingStudioPages::Services::CreatePage.call(
      parent_recording: root_recording,
      title: "Start from a URL",
      homepage: false,
      actor: user
    ).value!
  end
  restore_template_sections.call(start_recording, "start_from_url", user)
  publish_page.call(start_recording, "start-from-a-url", user)

  puts "Seeded Home, About, Tonight, Join, Walk in, and Start from a URL. Sign in as admin@admin.com / Password."
  puts "Seeded: Workspace '#{workspace.name}' with homepage '#{homepage_recording.recordable.title}'"
  puts "Seeded: Admin root '#{admin_root.name}'"
ensure
  Current.actor = previous_actor
end
