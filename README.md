# Recording Studio Pages

Compose public pages from Recording Studio recordings. A page is a recording. A section is a recording of one generic type. `section_type` picks the implementation from a registry.

This gem is for hosts that already run Recording Studio 4.x and want a page builder that stays inside the recordings tree.

## Install

Add the gem, then install and migrate:

```ruby
# Gemfile
gem "recording_studio_pages", github: "bowerbird-app/RecordingStudio_pages"
gem "recording_studio_publishable", github: "bowerbird-app/RecordingStudio_publishable"
gem "recording_studio_orderable", github: "bowerbird-app/RecordingStudio_orderable"
gem "recording_studio_admin", github: "bowerbird-app/RecordingStudio_admin"
```

```bash
bundle install
bin/rails generate recording_studio_pages:install
bin/rails generate recording_studio_pages:migrations
bin/rails db:migrate
```

Add the recordable types to Recording Studio:

```ruby
RecordingStudio.configure do |config|
  config.recordable_types = [
    "Workspace",
    "Folder",
    "RecordingStudioPages::Page",
    "RecordingStudioPages::Section"
  ]
  config.require_recordable_declarations = true
end
```

Mount the engines. Keep the page builder off `/` so it does not collide with RS Admin:

```ruby
mount RecordingStudioPages::Engine, at: "/recording_studio_pages"
mount RecordingStudioPublishable::Engine, at: "/"
recording_studio_admin_for :admin, at: "/admin", root_section: :pages
root to: "recording_studio_pages/homepages#show"
```

Point `/` at the homepage controller. Public pages use `recording_studio_pages/public`. That layout loads Flatpack tokens (`flat_pack/variables`, `flat_pack/application`) then Tailwind, and puts `data-theme="rounded"` on `html`. Do not reuse the Devise `application` layout for public pages — it is `max-w-md` for sign-in. Heroes render with Flatpack's Hero component at full width; other sections sit in `max-w-6xl`. Publishable `config.layout` is for Publishable's own screens; dummy sets it to `recording_studio/default_layout`.

## How a page is stored

```
Workspace (root recording)
  └── Page recording (title, homepage, template_key)
        ├── Section recording (section_type: hero, content, settings)
        ├── Section recording (section_type: feature_grid, ...)
        └── Publishable child (slug, status, SEO)
```

There is no `HeroSection` table. `section_type: "hero"` is a key on the generic section recording. A new section type is a registry entry, not a migration.

`Recording#record` parents a new child under the workspace root unless you pass `parent_recording:`. Page Builder services always pass it.

Order lives on `recording_studio_recordings.recording_studio_orderable_position` through RS Orderable. Publication, slug, and SEO live on the RS Publishable child. Do not add those columns to `recording_studio_pages_pages`.

## Register a section

The engine resets registries on reload, then registers built-ins, then runs `:register_sections`. Hosts and other gems must re-register in that hook or in `to_prepare`:

```ruby
# config/initializers/recording_studio_pages.rb
RecordingStudioPages.configure do |config|
  config.hooks.on(:register_sections) do
    RecordingStudioPages.register_section(
      key: :team_grid,
      name: "Team grid",
      category: "marketing",
      source: "host",
      component: "Host::TeamGridComponent",
      fields: {
        title: { type: :string, required: true },
        people: { type: :list, item: { name: :string, role: :string } },
        members: :recording_ids
      },
      settings: { variant: :string },
      variants: %w[photos names_only],
      data: ->(recording, content, settings, context) {
        Team.limit(8)
      }
    )
  end
end
```

`fields.title` may be `:string` or `{ type: :string, required: true }`. `recording_ids` stores Recording ids. Resolve the actual records at render time, or with `data:`. Do not copy domain records into section JSON.

Duplicate keys raise `RecordingStudioPages::DuplicateRegistration`. Unknown types do not crash render or delete data. They stay on the page until you register the type again.

`data:` is a proc. Use it when the section reads live records instead of only JSON. If the proc raises, render skips that payload and still draws the saved content.

`RecordingStudioPages.catalog` lists every registered section and template, including field types, required flags, settings, and variants. That catalog is the machine-readable surface for future API and MCP tooling.

## Register a template

```ruby
RecordingStudioPages.register_template(
  key: :launch,
  name: "Launch",
  source: "host",
  sections: [
    { type: :hero, content: { title: "We shipped" } },
    { type: :call_to_action, content: { title: "See the changelog" } }
  ]
)
```

`ApplyTemplate` creates new section recordings. Two pages that use the same template do not share rows.

## Built-in sections

hero, rich_text, image_text, logo_cloud, feature_grid, call_to_action.

Built-in template: `marketing_home`.

Rich text is JSON plus `sanitize`. Action Text expects a mutable record, so this gem does not use `has_rich_text`. Hero images are URL fields until Attachable is wired.

## Admin

RS Admin gets a Pages section. The nested section canvas lives at `/recording_studio_pages/admin/pages` because RS Admin is a hub of screens and widgets, not a nested recording editor. The editor lists sections in a Flatpack ordered, orderable list. Drag a row to change order. Copy, edit, turn off, and remove live in the row’s More menu. Copy duplicates a section into another generic section recording.

The editor is also the staff preview. Unpublished pages render there. They stay private on public routes. Add a section from the **Add section** dropdown on that editor. Picking a type posts immediately and Turbo updates the editor in place. Open **Edit** on a section to fill in its copy.

Writes need Accessible `:edit` on the configured admin root. Reads need `:view`.

`/admin` is the RS Admin hub. Switch the current root to **Admin** first. RS Admin forbids the hub while the current root is a workspace. The page builder editor does not require that switch.

Publishing and SEO stay on the RS Publishable child. The editor links to `/recordings/:id/publishable/edit`.

## Shared sections later

A future shared section can be a Section recording owned outside the page, referenced by a local child. This gem does not add a second relationship system. Do not store a second copy of global CTA copy in every page. The current tree already allows a section to live under a different parent; a later `section_type` can point at that recording through Recordable relationships.

## Dummy app

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Sign in with `admin@admin.com` / `Password`.

- `/` published homepage
- `/studio` dummy sandbox
- `/recording_studio_pages/admin/pages` page builder
- `/admin` RS Admin hub

## Upstream gaps

These are limits in sibling gems. This gem documents them instead of forking the siblings.

1. **Publishable slugs cannot be `/`.** The slug regex is `[a-z0-9]+(?:-[a-z0-9]+)*`, and public path templates must include `:uuid`. Homepage routing lives in Page Builder.
2. **Publishable slug uniqueness is not a hard unique constraint** across pages.
3. **RS Admin is a hub of screens and widgets**, not a nested canvas for ordered sections.
4. **Action Text assumes mutable records.** Section copy is JSON plus `sanitize`.
5. **Attachable is required by Publishable 0.2.1** even when you only want slug and status. Hero `image_url` is still a URL field, not an attachment recording.

## Version

0.3.0. Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.6.0`, Attachable `0.4.0`, Publishable `v0.2.1`, Orderable `v0.2.1`, Admin `v2.0.2`, FlatPack `v0.1.133`.
