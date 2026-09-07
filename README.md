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

Point `/` at the homepage controller. Publishable owns `/pages/:uuid/:slug`. The homepage cannot use that path. See [Upstream gaps](#upstream-gaps).

## How a page is stored

```
Workspace (root recording)
  └── Page recording (title, homepage, template_key)
        ├── Section recording (section_type: hero, content, settings)
        ├── Section recording (section_type: feature_grid, ...)
        └── Publishable child (slug, status, SEO)
```

There is no `HeroSection` table. `section_type: "hero"` is a key on the generic section recording. A new section type is a registry entry, not a migration.

Order lives on `recording_studio_recordings.recording_studio_orderable_position` through RS Orderable. Publication, slug, and SEO live on the Publishable child. Do not add those columns to `recording_studio_pages_pages`.

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
        title: :string,
        people: { type: :list, item: { name: :string, role: :string } }
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

Duplicate keys raise `RecordingStudioPages::DuplicateRegistration`. Unknown types do not crash render or delete data. They stay on the page until you register the type again.

`data:` is a proc. Use it when the section reads live records instead of only JSON. If the proc raises, render skips that payload and still draws the saved content.

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

RS Admin gets a Pages section. The actual editor is under `/recording_studio_pages/admin/pages`. Reorder is Move up and Move down. Flatpack has no sortable-list primitive.

Writes need Accessible `:edit` on the configured admin root. Reads need `:view`.

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
4. **Flatpack has no sortable-list primitive.** Admin uses Move up and Move down.
5. **Action Text assumes mutable records.** Section copy is JSON plus `sanitize`.
6. **Attachable is not wired.** Hero `image_url` is a URL, not an attachment recording.

## Version

0.3.0. Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.6.0`, Publishable `v0.2.1`, Orderable `v0.2.1`, Admin `v2.0.2`, FlatPack `v0.1.133`.
