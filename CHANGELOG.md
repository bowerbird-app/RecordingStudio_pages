# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.8] - 2026-09-21

Pages are a blank stack. Templates are gone.

### Removed
- `register_template`, `templates`, `template`, `ApplyTemplate`, and the in-memory template registry.
- Built-in `marketing_home` and `full_bleed_hero` recipes.
- Editor **Use a template**. New page **Start from a template**.
- Dummy `join`, `walk_in`, and `start_from_url` template registrations.

### Changed
- Dummy seed still creates Home, Tonight, Join, Walk in, and Start from a URL with `AddSection`.
- `RecordingStudioPages.catalog` is `{ sections:, ctas: }`.
- Create and revise no longer write `template_key`. The column stays.
- The editor action row is **Section**, Publishable’s Draft/Published control, then **Settings** with a cog.
- A section type name in the list opens that section’s edit screen.
- **Section** menu items show a type icon. Built-ins register `icon`. Hosts can pass `icon:` on `register_section`. Missing icons use `cube`.

### Upgrade notes
- Delete `register_template` calls and any `ApplyTemplate` usage. Add sections with `AddSection` or **Section**.
- If you overrode `_editor` or `new`, drop **Use a template** and **Start from a template**.
- Dummy hosts that registered Join / Walk in / Start from a URL templates should seed those pages with `AddSection` instead.
- Do not drop the `template_key` column in this release. New pages leave it blank.
- If you overrode `_editor`, put **Settings** last with `icon: "cog-6-tooth"`. Keep **Section** first and Publishable’s Draft/Published control in the middle.
- If you overrode `_section_row`, make the type name a Flatpack Link to that section’s edit screen.
- If you overrode `_add_section_dropdown`, pass `icon:` on each menu item (`definition.menu_icon`).
- Optional `icon:` on `register_section` is a Flatpack Heroicon name. Catalog includes it.

## [0.3.7] - 2026-09-18

The Admin Pages list keeps Status next to the row menu and links live names out. Page builder screens close to the original trigger.

### Changed
- Pages list columns are Page, Home, Updated at, Status, then the Edit / Trash menu. Status sits immediately left of Actions.
- Dummy’s Pages list puts **Page** under the title, not in the page-nav right slot.
- A live page name in the first column uses Publishable’s public View link (`PageLink`) and opens it in a new tab, so the public page is not captured by the Admin table Turbo Frame.
- Page builder screens that use Recording Studio default layout pass `page_nav_anchor_url` from the original trigger (`anchor_url`). Close leaves the back loop. Dummy’s signed-in home opens Admin and Pages with `anchor_url=/`. Hub **Page**, list **Page**, and **Edit** keep that incoming trigger — they do not retarget Close to the Pages list. Dummy default layout maps that slot to Flatpack PageNav `anchor_href`.

### Upgrade notes
- If you overrode the Admin Pages screen or dummy `recording_studio_admin/screens/show`, take **Page** under the title, the column order, live name links that use Publishable `PageLink` with `target="_blank"` and `data-turbo="false"`, and `preserve_anchor_url` on **Page**, or keep your list on purpose.
- If you overrode page builder views or dummy `recording_studio/default_layout`, pass the original trigger as `page_nav_anchor_url` and map it to Flatpack `anchor_href`. Thread the incoming `anchor_url` on Admin **Page** and **Edit**. Do not replace it with the Pages list. Unsafe `anchor_url` values are ignored.

## [0.3.6] - 2026-09-17

Pages hub cards open the Pages list. The list uses Publishable status, a Home filter, and a row menu.

### Added
- The Admin Pages list has a **Status** filter (Draft, Scheduled, Published) and a **Home page** filter (Home or Other pages). Status on each row is Publishable’s `render_publishable_quick_actions` control.
- Each row has an actions menu with **Edit** (the page editor) and **Trash**.
- Published and Drafts cards on the Pages hub open the Pages list. Drafts opens it with Draft selected. Published opens it with Published selected.

### Changed
- Dummy default layout only draws the pages flash slot when the Pages helper is on the controller, so RS Admin can share that layout.

### Upgrade notes
- If you overrode the Admin Pages screen, take the Status filter (Draft / Scheduled / Published), Home page filter, Publishable status control, and the Edit / Trash row menu, or keep your list on purpose.
- If you overrode the Published (was Live pages) or Drafts widgets, take `link_to` to the Pages screen. Published passes `status=Published`. Drafts passes `status=Draft`.

## [0.3.5] - 2026-09-17

The page editor uses Publishable’s Draft/Published control. Hero look lives under Style.

### Added
- Dummy installs Recording Studio Users `v0.11.0` so hero social CTAs can render Users Continue-with buttons instead of fake links to `/users/sign_in`.
- Dummy **Walk in** template and seeded page: a fullscreen hero image whose call to action is those Continue-with buttons.

### Changed
- Dummy pins Publishable `v0.3.0`. The page editor uses Publishable `render_publishable_quick_actions` (Draft, a scheduled date, or Published) instead of a **Publish** button. Public pages use Publishable document title, head tags, and a **Preview** badge on draft previews.
- Dummy pins Flatpack `v0.1.186`. Heroes pass Flatpack `align:` (Center or Left) and `on:` (dark or light photo). A fullscreen image hero fills the first viewport with `--hero-overlay-min-height: 100dvh` instead of a wrap around the section. Menu frost after scroll comes from Flatpack TopNav.
- Hero edit groups look under **Style**. **Preset** is On a dark photo or On a light photo, and only shows for a fullscreen picture. **Eyebrow**, **Headline**, and **Subtitle** are Flatpack ColorSwatch overrides (`eyebrow_color`, `title_color`, `body_color`). Headline paints overlay or surface headline tokens. Eyebrow and subtitle wrap those lines so they stay independent. Unused settings still save. A **Call to action** divider sits above the CTA field.
- The Pages admin hub puts **Page** first (primary, plus icon and the word Page) and **View all** second. **View all** opens the Admin Pages screen. **Page** opens the new-page form. Dummy’s Pages list also uses the plus icon on **Page**.
- The new-page form is a reading-width column. **Create page** is compact, not full width. Creating a page without ticking home stores `homepage: false` instead of writing null.
- Dummy pins Accessible `v0.9.1` and Attachable `v0.5.1` (Users requires Accessible `~> 0.8` and Attachable `~> 0.5.0`). Seed and tests grant access with `bootstrap_owner_access!` / `grant_access`.
- Dummy sign-in is Users email-first chrome. Password is the second screen. Google and Apple Continue-with buttons follow dummy test/development credentials under `omniauth:`.
- Dummy `social_logins` CTA calls Users OmniAuth helpers and draws Flatpack Continue-with buttons. It does not render the sign-in `continue_with_providers` partial (that partial includes an **Or** divider). The stack is `max-w-sm`, same as the Users auth shell, so the buttons do not fill a fullscreen hero. A left hero docks the stack; a centered hero keeps it centered.
- Dummy `url_form` CTA has no visible field name. The field and button sit in one row, vertically centered. Native Flatpack UrlInput and Button `:md` heights still differ (`--form-control-padding` vs `--button-padding-y-md`).
- Dummy page-builder screens use Recording Studio page nav only. Root switcher and Sign out stay on dummy host screens, not in the gem screen right slot.
- Page builder flashes use one `#flash` slot (`recording_studio_pages_flash`). Alert wins over notice. **Section** and Use a template replace that slot over Turbo; they do not draw a second notice in the editor.
- The page editor puts **Section** (plus icon), **Use a template**, **Settings**, and Publishable’s Draft/Published control in a row under the title. The two-column Grid sits under that row: section list on the left, live page on the right. Empty columns use Flatpack Empty State (**Add your first section** and **Preview**). The live column has no heading when it has content. The section list sits in a Card with padding (`padding: :md`, not `:none`). Each row is the section type name with a three-dot actions menu. Small screens stack the columns.
- Edit section uses the same Grid: form on the left, that one section on the right. The preview has no heading. Turned-off sections still preview. Small screens stack the columns.

### Upgrade notes
- Pin Publishable `v0.3.0` (or later). The page editor uses `render_publishable_quick_actions` (Draft / scheduled date / Published). Inline publish stays on the editor. Import Turbo on that layout. Public `recording_studio_pages/public` should call `publishable_document_title`, `publishable_head_tags`, and `publishable_preview_badge`. Include `RecordingStudioPublishable::ApplicationHelper` on Pages controllers. If you overrode `_editor` or the public layout, take those helpers, or keep your chrome on purpose.
- Pin Flatpack `v0.1.186` (or later). Drop any `h-dvh` wrap around Hero. On a fullscreen image hero, set `--hero-overlay-min-height: 100dvh` on the section. Hero **Align** is Center or Left (`align:`). **Preset** On a dark photo / On a light photo maps to `on:` and only belongs on a fullscreen picture. Optional hex `title_color` sets `--hero-overlay-text-color` / `--surface-content-color`. `eyebrow_color` and `body_color` wrap the eyebrow and subtitle so they do not share Flatpack’s muted token. Right align is not valid. Overlay copy sits high in the frame, not vertically centered. Menu frost is kit-owned; do not attach a window scroll listener. If you overrode the section form, take the **Call to action** divider, the Style group, and the gated preset.
- **View pages** is now **View all** and goes to `/admin/screens/pages`. **New page** is **Page**. Dummy draws those hub buttons with Flatpack `href:` (Admin 2.0.2 passes `url:`, which does not navigate) and puts a plus icon on **Page** on the hub and the Admin list. If you overrode the Admin section or screen view, take `href:` and the plus icon on Page, or keep your chrome on purpose.
- If you overrode `recording_studio_pages/admin/pages/new`, take the reading-width form (`max-w-xl`) and compact **Create page**. Unticked home no longer writes a null homepage.
- Add `recording_studio_user` (`v0.11.0`) in the host Gemfile when a hero should use Users Continue-with buttons. Run `recording_studio_user:install`, `recording_studio_user:migrations`, then `db:migrate`. Register `RecordingStudioUser::People` and `RecordingStudioUser::Profile`. Skip Devise sessions/registrations/passwords and mount `recording_studio_user_auth_for :users`.
- Bump Accessible to `>= 0.8` and run its migrations (`depends_on_recording_id`). Bump Attachable to `~> 0.5.0`.
- Call Users OmniAuth helpers from a hero CTA component (`recording_studio_user_omniauth_configured?`, `recording_studio_user_omniauth_provider_names`, `recording_studio_user_omniauth_authorize_path`). Cap the button stack at `max-w-sm` (Users auth does the same) so `w-full` buttons stay equal without filling a wide hero. Accept `align:` (`:left` or `:center`) and dock left with `mr-auto` when the hero is left; keep `mx-auto` when it is centered. Users’ `continue_with_providers` partial does not set that margin — it is for the sign-in screen. Continue-with buttons appear only for providers in Rails credentials under `omniauth:`. Do not put live OAuth secrets in the app.
- Hero `CtaRenderer` passes `align:` when the CTA component accepts that keyword. Components that only take `cta:` are unchanged. A URL-field CTA should omit the visible field name (no “Link” label). Flatpack UrlInput and Button `:md` do not share a control height (`--form-control-padding` vs `--button-padding-y-md`).
- Dummy test and development credentials use placeholder Google and Apple client ids so Join and Walk in can render. Replace those with real credentials in a host. Do not copy the dummy values.
- Do not define `recording_studio_pages_page_nav` to inject a root switcher or Sign out onto Pages screens. Those screens use Recording Studio page nav. Host chrome belongs on host screens.
- If you overrode `recording_studio_pages/admin/pages/_editor`, take the action row above the two-column Grid, **Section** with a plus icon, **Settings**, Publishable’s Draft/Published control, Empty State **Add your first section** / **Preview**, and the padded Card around the section list, or keep your layout on purpose. Drop any in-editor notice; flashes belong in `#flash`.
- If you overrode `recording_studio_pages/admin/pages/edit`, take the **Settings** title, or keep **Edit page** on purpose.
- Put `recording_studio_pages_flash` in the layout that wraps page builder screens (dummy uses Recording Studio default layout). That helper always renders `#flash`. **Section** and Use a template `turbo_stream.replace` it. Without that id, those Turbo flashes do not show.
- If you overrode `recording_studio_pages/admin/sections/edit` or `_form`, take the two-column Grid (form left, that section on the right, no Preview heading), the **Call to action** divider above a CTA field, and Hero **Style** (Eyebrow, Headline, Subtitle), or keep your layout on purpose.

## [0.3.4] - 2026-09-15

A Menu section puts a sticky top bar on a public page.

### Added
- Dummy signed-in `/` is a Flatpack sidebar shell with a root switcher in the top bar and buttons to the live example pages. Visitors still get the published homepage at `/`. Signed-in people preview that live page at `/site`.
- Built-in **Menu** (`top_nav`): name, optional mark, links, and a Join call to action, drawn with Flatpack TopNav. Full-bleed, like Hero. Links fold into **More** on a phone; Join stays on the bar.
- `register_section` accepts `full_bleed: true`. Hero and Menu set it. Other sections stay in `max-w-6xl`.
- `marketing_home` starts with a Menu. Dummy seed points Home’s links at the seeded About, Tonight, and Join pages.

### Changed
- Public layout asks for `viewport-fit=cover` so the bar can sit in the safe area.
- Dummy loads Flatpack Stimulus (`controllers/flat_pack`) so **More** works.
- Dummy imports Turbo and pins RS Admin Stimulus so the Pages hub Live pages and Drafts cards leave the shimmer and show counts.

### Upgrade notes
- Add a Menu from **Add section**, or apply **Marketing home**. Pages that already exist keep their sections until you add one.
- If you overrode `_section.html.erb`, take `full_bleed?` instead of hardcoding Hero.
- Public pages should load Flatpack JS. Dummy does that with `lazyLoadControllersFrom("controllers/flat_pack", application)`.
- Dummy only: signed-in `/` is the host home (sidebar, root switcher, example page buttons). Visitors still get the published homepage at `/`. Keep `root to: "recording_studio_pages/homepages#show"` in a host that wants the marketing page for everyone. Dummy uses `/site` for the live page while signed in.
- Dummy (and hosts) need `import "@hotwired/turbo-rails"` on the JS that serves `/admin`, plus the Admin Stimulus pin from `recording_studio_admin:install`. Without them, hub widgets stay on the skeleton.

## [0.3.3] - 2026-09-15

Rich text keeps the corner image off the words.

### Changed
- When a rich text card has a corner image, the copy gets extra bottom inset (`pb-56`) so the mark sits in the empty corner instead of on the last lines.

### Upgrade notes
- If you overrode the rich text component, take the extra bottom inset when an image is present, or keep your layout on purpose.

## [0.3.2] - 2026-09-15

Rich text is a full-width card with larger type and a named background.

### Changed
- Rich text layout is **Full width** or **Narrow**. Old `article` layout reads as full width.
- Rich text type is a display headline (`--text-4xl` / `--text-5xl`) and muted body (`--text-2xl`). Inset matches Flatpack Hero (`px-16 py-24`), not Card `lg`.
- Rich text background is **Default**, **Muted**, or **Inverted** (theme tokens, not a colour picker).
- Rich text can take an optional corner image (`image`, same Attachable field as hero). No image keeps today’s card.

### Upgrade notes
- Stored `variant: article` becomes full width on read.
- If you overrode the rich text component or the section settings form, take the Background select, display type, Hero inset (`px-16 py-24`), and the optional corner image, or keep your layout on purpose.

## [0.3.1] - 2026-09-09

Section photos live on the section as Attachable children. The JSON stores the attachment recording id.

### Added
- `RecordingStudioPages::Section` opts into Attachable (`image/*`) when that gem is loaded. Other gems that `register_section` do not include Attachable themselves.
- Built-in `hero`, `image_text`, and logo-cloud items use `image: { type: :attachment, kind: :image }`. The editor **Choose image** button opens Attachable's picker against that section.
- Public and editor preview resolve the saved id to an Active Storage blob path. Visitors do not use Attachable preview routes.
- Copying a section copies that section's photos and rewrites the saved ids.

### Changed
- `:attachment` field specs catalog `kind`, coerce blank to nil, and accept a recording id or a safe URL.
- Edit section puts **Update** and **Cancel** under the title, above the two-column grid. The buttons stay compact (not full width). Update reloads that section so the preview refreshes.

### Upgrade notes
- Bundle and mount `recording_studio_attachable` (`v0.5.1` or later). Add `RecordingStudioAttachable::Attachment` to `recordable_types`. Start Active Storage and eager-load `controllers/recording_studio_attachable`.
- Do not enable Attachable on Page for section photos. Do not add a Pages-owned Image type.
- Old `image_url` values still render. The next save writes `image` when someone picks a file. Templates may keep a static path such as `/images/hero-tonight.jpg` until they upload through the picker.
- If you overrode `recording_studio_pages/admin/sections/_field`, take the `:attachment` picker (or keep a URL field on purpose).
- If you overrode `recording_studio_pages/admin/sections/edit` or `_form`, take the **Update** / **Cancel** row above the grid and the stay-on-page Update redirect, or keep your layout on purpose.

## [0.3.0] - 2026-09-07

Recording Studio Page Builder. Pages and sections are recordings. `section_type` plus a registry pick the implementation. There is no parallel CMS schema.

### Added
- CTA registry. `register_cta` fills the hero slot. Built-in filling is `button`. Hosts register social logins, URL fields, and other fillings. Unknown CTA types skip the slot and keep the JSON.
- Dummy `social_logins` and `url_form` CTAs, plus **Join** and **Start from a URL** templates and seeded pages.
- `RecordingStudioPages::Page` and `RecordingStudioPages::Section` recordables. Page columns are `title`, `homepage`, and `template_key`. Section columns are `section_type`, `content`, `settings`, and `enabled`.
- Section and template registries. Duplicate keys raise. Unknown section types skip render and keep their rows.
- Built-in sections: `hero`, `rich_text`, `image_text`, `logo_cloud`, `feature_grid`, `call_to_action`. Built-in templates: `marketing_home` and `full_bleed_hero`. Dummy seeds a published **Tonight** page that is only the fullscreen hero.
- Services for create, revise, add, reorder, toggle, remove, apply template, and homepage uniqueness.
- Engine admin under `/recording_studio_pages/admin/pages` plus an RS Admin Pages section.
- Public homepage at `/` and Publishable public paths at `/pages/:uuid/:slug`.
- Duplicate a section through Recording Studio Duplicatable (`duplicate_in_place!`). Copy in the editor More menu uses that mixin.
- Required field flags and `recording_ids` in the section schema catalog.
- Dummy root switcher includes the Admin root so `/admin` can open after switching to it.
- Public pages use `recording_studio_pages/public` (Flatpack tokens then Tailwind, host Flatpack theme on `html`). Heroes use Flatpack Hero at full width; other sections use `max-w-6xl`. Dummy overrides `recording_studio/default_layout` so `data-theme` sits on `html` and `flat_pack/application` loads.
- Inner published pages use that same public layout, so a fullscreen hero is not boxed by the staff default layout.
- Fullscreen heroes fill the public viewport with a `100dvh` wrap (`h-full` on the Flatpack section). Flatpack’s `:centered_image` kit default is `min-h-[560px]`; TailwindMerge applies that after caller classes, so a competing `min-height` on the section cannot win.

### Changed
- Gem identity is `recording_studio_pages` `0.3.0`. Homepage is `https://github.com/bowerbird-app/RecordingStudio_pages`.
- Dummy `/` is the published homepage. Dummy sandbox moved to `/studio`.
- The page editor adds sections from an **Add section** dropdown. Turbo updates the editor. The old add-section library page redirects there.
- The editor lists sections in a Flatpack ordered list. Drag a row to reorder. Row actions live in a More menu.
- Public pages use the host Flatpack theme (`FlatPack.configuration.default_theme`) instead of hardcoding `rounded`. Dummy sets `rounded`.
- Built-in `marketing_home` copy is public-page language. Dummy seed restores Home to that template if the sections drift.
- Hero content uses `cta` (`type` plus that CTA’s fields). The editor picks the filling on the hero. Add section still lists section types only.

### Fixed
- Empty-state Flatpack Alerts use `style` and `description`.
- Drag-reorder persists through Flatpack List `orderable_url` (Flatpack `v0.1.162`). The list reloads when that save fails.
- Add and Copy append through Orderable `recording_studio_orderable_append!`.
- Remove page and remove section go through `trash!` when Trashable is present, otherwise `log_event!("trashed")` plus `trashed_at`.
- `page_parent_types` and `homepage_path` now gate create and the editor subtitle.
- The editor renders a live Preview of enabled sections. **Use a template** appends template sections in place.
- List fields skip blank extra slots and `_destroy` items.
- Registered section variants change public markup, not only Hero.
- Admin live/draft widgets count through Publishable `currently_published` instead of loading every page.
- `data:` failures log a warning instead of failing silently.
- Gem screens call `recording_studio_pages_nav` instead of dummy-only `dummy_page_nav`.

### Upgrade notes
- Bundle `recording_studio_duplicatable` and mount `RecordingStudioDuplicatable::Engine`. Copy on a section calls `duplicate_in_place!`; do not keep a host-local copy that re-adds the same section type.
- `RecordingStudioPages::Section` opts into Duplicatable when the gem is loaded. Page is not duplicatable.
- Pin dummy or host Gemfiles at Duplicatable `v0.4.1`, Orderable `v0.2.2`, and Flatpack `v0.1.162`.
- Define `recording_studio_pages_page_nav` if gem screens should share host chrome. Dummy wraps `dummy_page_nav`.
- Set Flatpack `orderable_url` on the page editor list. Do not add a second persist PATCH.
- Install Recording Studio Trashable if page and section remove should use `trash!`.
- Public pages use `min-h-dvh`. A fullscreen hero is a `100dvh` wrap around Flatpack Hero (`h-full` on the section). If you copied `recording_studio_pages/public`, take those classes; do not keep `h-full` on `html`/`body` mixed with `min-h-screen`.
- Set `FlatPack.configuration.default_theme` to your named theme. Public pages read that for `data-theme` on `html`. Dummy uses `rounded`. Do not hardcode `data-theme="rounded"` in a copied public layout.
- Built-in `marketing_home` copy changed. Pages that already used the template keep their saved words until you apply it again. Dummy `db:seed` restores Home to the current template.
- Hero JSON moves from `primary_action` to `cta: { type: "button", text:, url: }`. Old `primary_action` rows still render. The next save writes `cta`. Image-and-text and call-to-action still use `primary_action`.
- Register extra hero fillings in `:register_ctas`. The engine resets CTA registries on reload, same as sections.

### Notes
- Publishable cannot own `/` because slugs cannot be empty and public paths require `:uuid`. Page Builder owns homepage routing. See the README upstream gaps.

## [0.2.1] - 2026-09-01

### Added
- Full Cloud Agent development environment. `.cursor/install.sh` now provisions the whole stack at Build time on Cursor's default image — Ruby (pinned by `.ruby-version`), PostgreSQL 16, gem dependencies for both the gem and the dummy host app, the seeded dummy database, and compiled Tailwind/FlatPack CSS — then runs the existing `.cursor/fetch-skills.sh`. `snapshot` stays omitted so Builds run `install` as before.
- `.cursor/start.sh` per-boot hook that starts PostgreSQL and waits for readiness.
- `.cursor/environment.json` now declares `start` plus `rails-server` and `tailwind-watch` terminals and exposes port 3000, so a fresh Cloud Agent boots straight into a running, signed-in-ready dummy app.

### Notes
- The install script is idempotent; running it against a warm machine reuses the existing Ruby, packages, and gems.
- No gem runtime code changed. `.cursor/` files are excluded from the packaged gem.

## [0.2.0] - 2026-08-21

New addons copied from this template are born on Recording Studio 4.x.

### Added
- Gemspec dependency `recording_studio`, `~> 4.1`
- Dummy host wiring for Accessible (`enable_capability(:accessible, on: Workspace)`) and an opt-in `RecordingStudio::Capabilities::Example.to` mixin. `.to` wraps core 4.2.0 `include_for` (not a fourth verb, and not a raw `enable_capability` / `set_capability_options` path). Installing the gem does not enable the mixin globally; only dummy Workspace opts in.
- `bin/rename_gem` leftover-identity rewrite/verification for README, homepage, and changelog URLs that still say `RecordingStudioPages` or point at `bowerbird-app/recording_studio_pages`

### Changed
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.6.0`, Root Switchable `v0.5.0`, FlatPack `v0.1.133`
- Dummy authenticated layout is Recording Studio's default layout plus FlatPack CSS/JS; Devise keeps its own sign-in layout
- Dummy app security pins: Rails `8.1.3.1`, `json` `2.21.2`, `mail` `2.9.1`, Brakeman `8.0.6`
- Require `RecordingStudio::Hooks` and `RecordingStudio::Services::BaseService` from core instead of shipping copies

### Removed
- Copied `lib/recording_studio_pages/hooks.rb` and `lib/recording_studio_pages/services/base_service.rb`
- Product-shipped `ExampleService`
- Custom `flat_pack_sidebar` authenticated shell

### Upgrade notes
- Point dummy or host Gemfiles at Recording Studio `v4.2.0` (not `recording_studio/v3.0.0`)
- Add `spec.add_dependency "recording_studio", "~> 4.1"` to addon gemspecs
- Include `RecordingStudio::UsesDefaultLayout` (or set `layout "recording_studio/default_layout"`) for authenticated screens
- Delete any copied Hooks or BaseService files and require the core classes
- Keep recordable declarations; they are required, not a v3-only concern
- If Accessible is bundled, call `RecordingStudio.enable_capability(:accessible, on: Workspace)` (or your root type)

## [0.1.2] - 2026-07-21

### Changed
- Bumped the dummy app FlatPack dependency from `v0.1.33` to `v0.1.129`

## [0.1.1] - 2026-04-28

### Changed
- Bumped the dummy app FlatPack dependency from `0.1.2` to `0.1.33` and pinned it by tag in `test/dummy/Gemfile`

## [0.1.0] - 2025-12-04

### Added
- Initial release
- Rails mountable engine structure
- PostgreSQL with UUID primary keys support
- TailwindCSS v4 integration
- GitHub Codespaces devcontainer configuration
- Docker Compose setup with PostgreSQL and Redis
- Install generator for host applications
- Comprehensive README and documentation
- Basic test suite with Minitest

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_pages/compare/v0.3.8...HEAD
[0.3.8]: https://github.com/bowerbird-app/RecordingStudio_pages/compare/v0.3.7...v0.3.8
[0.3.7]: https://github.com/bowerbird-app/RecordingStudio_pages/compare/v0.3.6...v0.3.7
[0.3.6]: https://github.com/bowerbird-app/RecordingStudio_pages/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/bowerbird-app/RecordingStudio_pages/compare/v0.3.4...v0.3.5
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_pages/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/bowerbird-app/RecordingStudio_pages/releases/tag/v0.2.1
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_pages/releases/tag/v0.2.0
[0.1.2]: https://github.com/bowerbird-app/RecordingStudio_pages/releases/tag/v0.1.2
[0.1.1]: https://github.com/bowerbird-app/RecordingStudio_pages/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_pages/releases/tag/v0.1.0
