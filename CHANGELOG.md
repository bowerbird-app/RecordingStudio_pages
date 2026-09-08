# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Dummy installs Recording Studio Users `v0.11.0` so hero social CTAs can render Users Continue-with buttons instead of fake links to `/users/sign_in`.
- Dummy **Walk in** template and seeded page: a fullscreen hero image whose call to action is those Continue-with buttons.

### Changed
- Dummy pins Accessible `v0.9.1` and Attachable `v0.5.1` (Users requires Accessible `~> 0.8` and Attachable `~> 0.5.0`). Seed and tests grant access with `bootstrap_owner_access!` / `grant_access`.
- Dummy sign-in is Users email-first chrome. Password is the second screen. Google and Apple Continue-with buttons follow dummy test/development credentials under `omniauth:`.
- Dummy `social_logins` CTA calls Users OmniAuth helpers and draws Flatpack Continue-with buttons. It does not render the sign-in `continue_with_providers` partial (that partial includes an **Or** divider). The stack is `max-w-sm`, same as the Users auth shell, so the buttons do not fill a fullscreen hero.
- Dummy page-builder screens use Recording Studio page nav only. Root switcher and Sign out stay on dummy `/studio` and `/docs`, not in the gem screen right slot.
- The page editor uses a two-column Flatpack Grid: section list on the left, live page on the right. The live column has no heading. Small screens stack the columns.

### Upgrade notes
- Add `recording_studio_user` (`v0.11.0`) in the host Gemfile when a hero should use Users Continue-with buttons. Run `recording_studio_user:install`, `recording_studio_user:migrations`, then `db:migrate`. Register `RecordingStudioUser::People` and `RecordingStudioUser::Profile`. Skip Devise sessions/registrations/passwords and mount `recording_studio_user_auth_for :users`.
- Bump Accessible to `>= 0.8` and run its migrations (`depends_on_recording_id`). Bump Attachable to `~> 0.5.0`.
- Call Users OmniAuth helpers from a hero CTA component (`recording_studio_user_omniauth_configured?`, `recording_studio_user_omniauth_provider_names`, `recording_studio_user_omniauth_authorize_path`). Cap the button stack at `max-w-sm` (Users auth does the same) so `w-full` buttons stay equal without filling a wide hero. Keep `recording_studio_user/omniauth/continue_with_providers` on the sign-in screen. Continue-with buttons appear only for providers in Rails credentials under `omniauth:`. Do not put live OAuth secrets in the app.
- Dummy test and development credentials use placeholder Google and Apple client ids so Join and Walk in can render. Replace those with real credentials in a host. Do not copy the dummy values.
- Do not define `recording_studio_pages_page_nav` to inject a root switcher or Sign out onto Pages screens. Those screens use Recording Studio page nav. Host chrome belongs on host screens.
- If you overrode `recording_studio_pages/admin/pages/_editor`, take the two-column Grid (edit left, preview right) or keep your layout on purpose.

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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_pages/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_pages/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/bowerbird-app/RecordingStudio_pages/releases/tag/v0.2.1
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_pages/releases/tag/v0.2.0
[0.1.2]: https://github.com/bowerbird-app/RecordingStudio_pages/releases/tag/v0.1.2
[0.1.1]: https://github.com/bowerbird-app/RecordingStudio_pages/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_pages/releases/tag/v0.1.0
