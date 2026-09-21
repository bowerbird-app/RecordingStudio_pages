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

public_page_path = lambda do |page_recording|
  child = page_recording&.publishable_child_recording
  next if child.blank?

  RecordingStudioPublishable::Routing.url_for(publishable_recording: child)
end

sync_house_menu = lambda do |page_recording, links, join_url, actor|
  menu = RecordingStudioPages::Composition.section_recordings_for(page_recording).find do |recording|
    recording.recordable.section_type == "top_nav"
  end
  next unless menu

  desired_links = links.select { |link| link["url"].present? }
  current = menu.recordable.content
  current_cta = current["cta"] || {}
  next if current["name"] == "House" &&
          current["links"] == desired_links &&
          current_cta["type"] == "button" &&
          current_cta["text"] == "Join" &&
          current_cta["url"] == join_url

  RecordingStudioPages::Services::ReviseSection.call(
    section_recording: menu,
    content: current.merge(
      "name" => "House",
      "links" => desired_links,
      "cta" => { "type" => "button", "text" => "Join", "url" => join_url }
    ),
    settings: menu.recordable.settings,
    actor: actor
  ).value!
end

ensure_sections = lambda do |page_recording, entries, actor|
  expected_types = entries.map { |entry| entry.fetch(:type).to_s }
  hero_entry = entries.find { |entry| entry.fetch(:type).to_s == "hero" }
  expected_hero = (hero_entry&.fetch(:content) || {}).to_h.stringify_keys
  expected_hero_title = expected_hero["title"]
  expected_cta_type = expected_hero.dig("cta", "type")
  expected_image_url = expected_hero["image"] || expected_hero["image_url"]
  expected_settings = (hero_entry&.fetch(:settings) || {}).to_h.stringify_keys
  sections = RecordingStudioPages::Composition.section_recordings_for(page_recording)
  types = sections.map { |recording| recording.recordable.section_type }
  hero = sections.find { |recording| recording.recordable.section_type == "hero" }&.recordable
  hero_title = hero&.content&.[]("title")
  hero_cta_type = hero&.content&.dig("cta", "type")
  hero_image = hero&.content&.[]("image").presence || hero&.content&.[]("image_url")
  hero_settings = (hero&.settings || {}).to_h.stringify_keys
  legacy_cta = hero&.content&.[]("primary_action").present? && hero_cta_type.blank?
  cta_drift = expected_cta_type.present? && hero_cta_type != expected_cta_type
  image_drift = expected_image_url.present? && hero_image != expected_image_url
  settings_drift = expected_settings.any? { |key, value| hero_settings[key] != value }
  return if types == expected_types && hero_title == expected_hero_title && !legacy_cta && !cta_drift &&
            !image_drift && !settings_drift

  sections.each do |recording|
    RecordingStudioPages::Services::RemoveSection.call(section_recording: recording, actor: actor).value!
  end
  entries.each do |entry|
    RecordingStudioPages::Services::AddSection.call(
      page_recording: page_recording.reload,
      section_type: entry.fetch(:type),
      content: entry.fetch(:content),
      settings: entry.fetch(:settings, {}),
      enabled: entry.fetch(:enabled, true),
      actor: actor
    ).value!
  end
end

home_sections = [
  {
    type: :top_nav,
    content: {
      name: "House",
      links: [
        { text: "About", url: "/" },
        { text: "Tonight", url: "/" }
      ],
      cta: { type: "button", text: "Join", url: "/users/sign_in" }
    }
  },
  {
    type: :hero,
    content: {
      eyebrow: "Open tonight",
      title: "The page is the front door",
      body: "Stack a few pieces. Move them around. Put it live when it feels like a site.",
      cta: { type: "button", text: "Come in", url: "/users/sign_in" }
    },
    settings: { variant: "centered", alignment: "left" }
  },
  {
    type: :logo_cloud,
    content: {
      title: "Names on the door",
      items: [
        { name: "House lights" },
        { name: "Late show" },
        { name: "Stage door" }
      ]
    }
  },
  {
    type: :feature_grid,
    content: {
      title: "What you get",
      items: [
        { title: "Pages", body: "A page is a stack you can reorder." },
        { title: "Pieces", body: "Each piece has a job. Change the layout without starting over." },
        { title: "Reuse", body: "Add a type once, then drop it on any page." }
      ]
    },
    settings: { variant: "three_column" }
  },
  {
    type: :call_to_action,
    content: {
      title: "Ready when you are",
      body: "Keep it private until it looks right. Then put it on the street.",
      primary_action: { text: "Have a look", url: "/users/sign_in" }
    }
  }
]

tonight_sections = [
  {
    type: :hero,
    content: {
      eyebrow: "Doors at eight",
      title: "The floor is already warm",
      body: "One picture. One line. Come in if you want a seat.",
      cta: { type: "button", text: "Take a seat", url: "/users/sign_in" }
    },
    settings: { variant: "fullscreen_image", alignment: "left" }
  }
]

join_sections = [
  {
    type: :hero,
    content: {
      eyebrow: "Members",
      title: "Come as you are",
      body: "Use the door you already have.",
      cta: { type: "social_logins" }
    },
    settings: { variant: "centered" }
  }
]

walk_in_sections = [
  {
    type: :hero,
    content: {
      eyebrow: "Members",
      title: "The lights are already on",
      body: "Use the door you already have.",
      image_url: "/images/hero-tonight.jpg",
      cta: { type: "social_logins" }
    },
    settings: { variant: "fullscreen_image", alignment: "left" }
  }
]

start_from_url_sections = [
  {
    type: :hero,
    content: {
      eyebrow: "Quick start",
      title: "Got a link?",
      body: "Paste it. We'll take it from there.",
      cta: {
        type: "url_form",
        placeholder: "https://",
        button_text: "Open it"
      }
    },
    settings: { variant: "centered" }
  }
]

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

  ensure_sections.call(homepage_recording, home_sections, user)
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
      content: {
        title: "About this studio, in your words",
        body: "This page sits with the rest of the site. Pieces stack underneath. Use a hero when you want a picture. Use this when you want the words.",
        image: "/images/rich-text-corner.png"
      },
      settings: { variant: "full_width", background: "muted" },
      actor: user
    ).value!
  end

  about_section = RecordingStudioPages::Composition.section_recordings_for(about_recording).find do |recording|
    recording.recordable.section_type == "rich_text"
  end
  if about_section && about_section.recordable.content["image"].blank?
    RecordingStudioPages::Services::ReviseSection.call(
      section_recording: about_section,
      content: about_section.recordable.content.merge(
        "title" => "About this studio, in your words",
        "image" => "/images/rich-text-corner.png"
      ),
      settings: about_section.recordable.settings.merge("variant" => "full_width", "background" => "muted"),
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

  ensure_sections.call(tonight_recording, tonight_sections, user)

  hero_recording = RecordingStudioPages::Composition.section_recordings_for(tonight_recording).find do |recording|
    recording.recordable.section_type == "hero"
  end
  if hero_recording && hero_recording.recordable.content["image"].blank? &&
     hero_recording.recordable.content["image_url"].blank?
    RecordingStudioPages::Services::ReviseSection.call(
      section_recording: hero_recording,
      content: hero_recording.recordable.content.merge("image" => "/images/hero-tonight.jpg"),
      settings: hero_recording.recordable.settings.merge("variant" => "fullscreen_image", "alignment" => "left"),
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
  ensure_sections.call(join_recording, join_sections, user)
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
  ensure_sections.call(walk_in_recording, walk_in_sections, user)
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
  ensure_sections.call(start_recording, start_from_url_sections, user)
  publish_page.call(start_recording, "start-from-a-url", user)

  join_url = public_page_path.call(join_recording) || "/users/sign_in"
  house_links = [
    { "text" => "About", "url" => public_page_path.call(about_recording) },
    { "text" => "Tonight", "url" => public_page_path.call(tonight_recording) }
  ]
  sync_house_menu.call(homepage_recording, house_links, join_url, user)

  puts "Seeded Home, About, Tonight, Join, Walk in, and Start from a URL. Sign in as admin@admin.com / Password."
  puts "Seeded: Workspace '#{workspace.name}' with homepage '#{homepage_recording.recordable.title}'"
  puts "Seeded: Admin root '#{admin_root.name}'"
ensure
  Current.actor = previous_actor
end
