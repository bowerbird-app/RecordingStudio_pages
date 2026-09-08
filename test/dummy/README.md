# Dummy App

This Rails app exists to validate the Recording Studio Page Builder in a real host application.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Workspace roots plus seeded page and section recordings
- Public homepage at `/` from a published page recording. Dummy seed restores the sample Home template if sections drift.
- Staff page composition at `/recording_studio_pages/admin/pages`. Add a section from the editor dropdown. Use a template. Preview enabled sections on the same screen. Drag sections to reorder. Copy a section from More (Recording Studio Duplicatable). Remove a page from Edit page.
- RS Admin Pages section at `/admin`
- Recording Studio default layout, FlatPack assets (including `flat_pack/application`), and Tailwind source scanning via `tmp/tailwind` mirrors. Public pages use a full-width layout and the host Flatpack theme (`rounded` here). Devise sign-in stays `max-w-md`.
- Dummy-only `/docs/*` and `/studio` pages for host-app sandboxing

## Quick Start

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Run the commands above from the dummy app directory, not the repository root.

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Useful Routes

- `/` - published homepage
- `/pages/:uuid/tonight` - seeded **Tonight** page: one fullscreen hero, public URL (not the editor preview)
- `/studio` - dummy sandbox
- `/recording_studio` - redirects to `/studio` while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/recording_studio_pages/admin/pages` - page builder
- `/admin` - RS Admin hub. Switch the current root to **Admin** first. The hub returns 403 while a workspace is selected.
- `/users/sign_in` - Devise sign-in page
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` - dummy-only starter pages
- `/up` - Rails health check

## Why This App Exists

Use this app to verify page composition, publish, and public render before you copy the gem into another host. If a layout, route, asset source, or Recording Studio initializer change breaks here, the gem needs the same fix.
