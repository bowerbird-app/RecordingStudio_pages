# Dummy App

This Rails app exists to validate the Recording Studio Page Builder in a real host application.

## What It Covers

- Recording Studio Users for sign-in, People, Profile, and Continue-with social buttons
- A seeded admin person (`admin@admin.com` / `Password`) with a Profile under the shared People root
- `Current.actor` wiring for Recording Studio events
- Workspace roots plus seeded page and section recordings
- Public homepage at `/` from a published page recording. Dummy seed restores the sample Home template if sections drift.
- Staff page composition at `/recording_studio_pages/admin/pages`. Add a section from the editor dropdown. Use a template. Edit the section list in a padded Card in the first column and see enabled sections in the second. Drag sections to reorder. Copy a section from More (Recording Studio Duplicatable). Remove a page from Edit page.
- RS Admin Pages section at `/admin`. Switch to the Admin root first. The hub also lists **Users**.
- Recording Studio default layout, FlatPack assets (including `flat_pack/application`), and Tailwind source scanning via `tmp/tailwind` mirrors. Public pages use a full-width layout and the host Flatpack theme (`rounded` here). Users auth uses the gem's centered layout, not the dummy `max-w-md` application layout. Page builder screens use Recording Studio page nav (back and close). Dummy `/studio` and `/docs` add a root switcher and Sign out.
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

Sign-in is email first (**Continue with email**), then password. Google and Apple Continue-with buttons show because dummy test/development credentials include placeholder `omniauth:` keys. Those ids are not real OAuth clients. Hosts put live secrets in Rails credentials and leave `omniauth_providers` empty.

## Useful Routes

- `/` - published homepage
- `/pages/:uuid/tonight` - seeded **Tonight** page: one fullscreen hero, public URL (not the editor preview)
- `/pages/:uuid/join` - seeded **Join** page: one centered hero whose call to action is Users Continue-with buttons
- `/pages/:uuid/walk-in` - seeded **Walk in** page: one fullscreen hero image whose call to action is the same Continue-with buttons
- `/pages/:uuid/start-from-a-url` - seeded **Start from a URL** page: one hero with a paste-a-link field
- `/start` - dummy catcher for that URL field
- `/studio` - dummy sandbox
- `/recording_studio` - redirects to `/studio` while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/recording_studio_pages/admin/pages` - page builder
- `/recording_studio_users/profile` - My Profile
- `/admin` - RS Admin hub. Switch the current root to **Admin** first. The hub returns 403 while a workspace is selected.
- `/users/sign_in` - Users email-first sign-in
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` - dummy-only starter pages
- `/up` - Rails health check

## Why This App Exists

Use this app to verify page composition, publish, and public render before you copy the gem into another host. If a layout, route, asset source, or Recording Studio initializer change breaks here, the gem needs the same fix.
