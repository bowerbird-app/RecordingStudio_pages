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
gem "recording_studio_duplicatable", github: "bowerbird-app/RecordingStudio_duplicatable"
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
mount RecordingStudioDuplicatable::Engine, at: "/recording_studio_duplicatable"
mount RecordingStudioPublishable::Engine, at: "/"
recording_studio_admin_for :admin, at: "/admin", root_section: :pages
root to: "recording_studio_pages/homepages#show"
```

Point `/` at the homepage controller. Public pages use `recording_studio_pages/public`. That layout loads Flatpack tokens (`flat_pack/variables`, `flat_pack/application`) then Tailwind, and puts the host’s named Flatpack theme on `html` (`FlatPack.configuration.default_theme`, dummy `rounded`). Do not reuse the Devise `application` layout for public pages — it is `max-w-md` for sign-in. Heroes render with Flatpack's Hero component at full width; other sections sit in `max-w-6xl`. Publishable `config.layout` is for Publishable's own screens; dummy sets it to `recording_studio/default_layout`.

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

The engine resets registries on reload, then registers built-ins, then runs `:register_sections` and `:register_ctas`. Hosts and other gems must re-register in those hooks or in `to_prepare`:

```ruby
# config/initializers/recording_studio_pages.rb
RecordingStudioPages.configure do |config|
  config.page_parent_types = %w[Workspace Folder]
  config.homepage_path = "/"
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

`page_parent_types` is the allow list for new pages. `CreatePage` rejects anything else, including a blank parent. `homepage_path` is the public home URL shown in the editor when the page is marked as home.

`fields.title` may be `:string` or `{ type: :string, required: true }`. `recording_ids` stores Recording ids. Resolve the actual records at render time, or with `data:`. Do not copy domain records into section JSON.

Duplicate keys raise `RecordingStudioPages::DuplicateRegistration`. Unknown types do not crash render or delete data. They stay on the page until you register the type again.

`data:` is a proc. Use it when the section reads live records instead of only JSON. If the proc raises, render logs a warning, skips that payload, and still draws the saved content.

`RecordingStudioPages.catalog` lists every registered section, template, and call to action, including field types, required flags, settings, and variants. That catalog is the machine-readable surface for future API and MCP tooling.

## Register a call to action

A hero has one slot under the copy. Pages fills it from a **CTA registry**, not by forking the hero. The built-in filling is a button (`text` + `url`). Hosts and other gems register more fillings — social logins, a URL field, a waitlist form — and pick them on the hero, or bake them into a template.

```ruby
RecordingStudioPages.configure do |config|
  config.hooks.on(:register_ctas) do
    RecordingStudioPages.register_cta(
      key: :social_logins,
      name: "Social logins",
      source: "host",
      component: "Host::SocialLoginsComponent"
    )
    RecordingStudioPages.register_cta(
      key: :url_form,
      name: "URL field",
      source: "host",
      component: "Host::UrlFormComponent",
      fields: {
        placeholder: { type: :string, label: "Placeholder" },
        button_text: { type: :string, label: "Button text" }
      }
    )
  end
end
```

The component receives `cta:` — the saved hash, including `type`. Duplicate keys raise. Unknown CTA types skip the slot and keep the JSON, same as unknown sections.

Hero content looks like `cta: { type: "button", text: "Come in", url: "/users/sign_in" }`. Saved rows that still have `primary_action` upgrade on read; the next save writes `cta`. Image-and-text and call-to-action sections still use `primary_action` as a single link.

New page still starts from a **template**. The template names the CTA. Editing the hero is where you change Button / Social logins / URL field. Add section does not list CTAs.

Dummy registers `social_logins` and `url_form`, plus **Join**, **Walk in**, and **Start from a URL** templates, so a one-section landing can be a button, sign-in buttons, or a paste-a-link field. Dummy `social_logins` calls Recording Studio Users OmniAuth helpers (`recording_studio_user_omniauth_provider_names`, `recording_studio_user_omniauth_authorize_path`, and the provider label/logo helpers) and draws stacked Flatpack Continue-with buttons. The stack is `max-w-sm` (same cap as the Users auth shell) so `w-full` buttons stay equal without stretching across a fullscreen hero. It does not render `recording_studio_user/omniauth/continue_with_providers` — that partial is for the sign-in screen and includes an **Or** divider. Dummy test and development credentials enable Google and Apple so Join and Walk in can show those buttons. Hosts leave `omniauth_providers` empty and put real secrets in credentials; do not copy dummy client ids.

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

hero, rich_text, image_text, logo_cloud, feature_grid, call_to_action. Registered variants change layout: image left/right, narrow rich text, compact logos, feature column counts, and CTA banner vs card.

- Built-in templates: `marketing_home` (hero, logos, features, CTA) and `full_bleed_hero` (one fullscreen hero). Dummy also registers `join` (centered hero with social logins), `walk_in` (fullscreen hero image with social logins), and `start_from_url` (hero with a URL field). Dummy seeds published **Tonight**, **Join**, **Walk in**, and **Start from a URL** pages. Open Tonight at `/pages/:uuid/tonight`, Join at `/pages/:uuid/join`, Walk in at `/pages/:uuid/walk-in`, and the URL landing at `/pages/:uuid/start-from-a-url`. Those public URLs are the page, not the editor preview. A fullscreen hero fills the viewport (`100dvh`); Flatpack’s image hero is otherwise `min-h-[560px]`. Dummy Home is the `marketing_home` sample; seed restores that template if the sections drift (a second hero from **Use a template**, old copy, and so on).

Rich text is JSON plus `sanitize`. Action Text expects a mutable record, so this gem does not use `has_rich_text`. Hero images are URL fields until Attachable is wired.

List fields skip blank extra slots and items marked `_destroy`.

## Admin

RS Admin gets a Pages section. The nested section canvas lives at `/recording_studio_pages/admin/pages` because RS Admin is a hub of screens and widgets, not a nested recording editor. The editor lists sections in a padded Flatpack Card around an ordered, orderable list. Drag a row to change order. Copy, edit, turn off, and remove live in the row’s More menu. Copy uses Recording Studio Duplicatable (`duplicate_in_place!`) so the new row is another generic section recording under the same page, then Orderable `recording_studio_orderable_append!` puts it at the end.

The editor is a two-column Flatpack Grid: the section list on the left, the live page on the right. The live column has no heading. Small screens stack those columns. Enabled sections use the same components as the public page. Unpublished pages stay private on public routes. Add a section from **Add section**. Apply **Use a template** to append that template’s sections. Open **Edit page** to rename, set home, or remove the page.

Gem screens call `recording_studio_pages_nav`, which uses Recording Studio page nav (back and close). That default layout stays host-agnostic. Dummy `/studio` and `/docs` add a root switcher and Sign out through `dummy_page_nav`. Do not wrap that host chrome onto gem screens.

Writes need Accessible `:edit` on the configured admin root. Reads need `:view`.

`/admin` is the RS Admin hub. Switch the current root to **Admin** first. RS Admin forbids the hub while the current root is a workspace. The page builder editor does not require that switch.

Publishing and SEO stay on the RS Publishable child. The editor links to `/recordings/:id/publishable/edit`. Public inner pages at `/pages/:uuid/:slug` use the same `recording_studio_pages/public` layout as `/`, so a fullscreen hero can actually go edge to edge.

Drag-reorder persists through Flatpack List `orderable_url`. The Pages Stimulus controller only blocks More-menu drags and reloads if that save fails.

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
- `/pages/:uuid/tonight` one fullscreen hero (seeded **Tonight**)
- `/pages/:uuid/join` one hero with sign-in buttons (seeded **Join**)
- `/pages/:uuid/walk-in` one fullscreen hero with sign-in buttons (seeded **Walk in**)
- `/pages/:uuid/start-from-a-url` one hero with a URL field (seeded **Start from a URL**)
- `/start` dummy catcher for that URL field
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
6. **Core has no `trash!`.** Page Builder calls `trash!` when Trashable is present; otherwise it logs `trashed` and sets `trashed_at`. Install Trashable for a real trash path.
7. **Flatpack ordered list items are `display:flex`**, so native `<ol>` markers stay hidden. Page Builder sets `leading:` to the position number.

## Version

0.3.0. Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.9.1`, Attachable `v0.5.1`, Users `v0.11.0`, Publishable `v0.2.1`, Orderable `v0.2.2`, Duplicatable `v0.4.1`, Admin `v2.0.2`, FlatPack `v0.1.162`.

## Upgrade

1. Bundle `recording_studio_pages` with Publishable, Orderable, and Duplicatable.
2. Mount Pages, Duplicatable, and Publishable. Keep Pages off `/`.
3. `RecordingStudioPages::Section` already opts into Duplicatable when that gem is loaded. Do not add a second copy path.
4. Public pages load `flat_pack/application` and use the host Flatpack theme on `html` (`FlatPack.configuration.default_theme`). Dummy sets `rounded`.
5. Pin Flatpack `v0.1.162` (or later) so List `orderable_url` persists drag. Pin Orderable `v0.2.2` (or later) so Copy and Add call `recording_studio_orderable_append!`.
6. Gem screens use Recording Studio page nav. Dummy `/studio` and `/docs` keep host chrome (root switcher, Sign out). Do not put that on gem screens.
7. Install Recording Studio Trashable if you want `trash!` instead of a `trashed_at` write.
8. Built-in hero content uses `cta` (`type` plus that CTA’s fields) instead of `primary_action`. Old `primary_action` rows still render. The next save writes `cta`. Image-and-text and call-to-action are unchanged.
9. For a social Continue-with CTA, install Recording Studio Users `v0.11.0`, register People and Profile, and call the Users OmniAuth helpers from a CTA component. Dummy Join and Walk in do that. The `continue_with_providers` partial is for the sign-in screen. Continue-with buttons follow Rails credentials under `omniauth:`.
