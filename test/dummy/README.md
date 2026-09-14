# Dummy App

This Rails app exists to validate the Recording Studio Page Builder in a real host application.

## What It Covers

- Recording Studio Users for sign-in, People, Profile, and Continue-with social buttons
- A seeded admin person (`admin@admin.com` / `Password`) with a Profile under the shared People root
- `Current.actor` wiring for Recording Studio events
- Workspace roots plus seeded page and section recordings
- Public homepage at `/` for visitors, from a published page recording. Dummy seed restores the sample Home template if sections drift.
- Signed-in `/` is a Flatpack sidebar of example pages, not a landing page. Switch to the Admin root and that same home is a **Pages** button to `/admin`.
- Staff compose pages through the Admin **Pages** section. Dummy `AdminRoot` enables `section :pages`. Switch to the Admin root, then open `/admin`. Access is that section. The list is `/admin/screens/pages`. **New** and **Open** are jobs under that section. The nested editor still lives at `/recording_studio_pages/admin/pages/:id` because Admin is not a nested canvas; it authorizes the Pages resource and returns to the Admin list. Add a section from the editor dropdown. Use a template. Edit the section list in a padded Card in the first column and see enabled sections in the second. Open a section for **Update** and **Cancel** under the title, the form on the left, and a live preview on the right. Update stays on that section. **Choose image** on hero, image-and-text, and logo items opens the Attachable picker for that section. Drag sections to reorder. Copy a section from the row’s three-dot menu (Recording Studio Duplicatable; photos come along). Remove a page from Edit page.
- Public pages stay on Recording Studio Publishable (`/` for visitors and `/pages/:uuid/:slug`). Visitors do not go through Admin.
- Recording Studio default layout, FlatPack assets (including `flat_pack/application`), and Tailwind source scanning via `tmp/tailwind` mirrors. Public pages use a full-width layout and the host Flatpack theme (`rounded` here). Users auth uses the gem's centered layout, not the dummy `max-w-md` application layout. Page builder screens use Recording Studio page nav (back and close). Signed-in dummy home uses a Flatpack sidebar. Dummy `/docs` adds a root switcher and Sign out.

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

- `/` - visitors see the published homepage. Signed-in people see the sidebar home (example pages). On the Admin root that home is a **Pages** button to `/admin`.
- `/pages/:uuid/tonight` - seeded **Tonight** page: one fullscreen hero, public URL (not the editor preview)
- `/pages/:uuid/join` - seeded **Join** page: one centered hero whose call to action is Users Continue-with buttons
- `/pages/:uuid/walk-in` - seeded **Walk in** page: one fullscreen hero image whose call to action is the same Continue-with buttons
- `/pages/:uuid/start-from-a-url` - seeded **Start from a URL** page: one hero with a paste-a-link field
- `/start` - dummy catcher for that URL field
- `/studio` - same signed-in home as `/`
- `/recording_studio` - redirects to `/` while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/admin` - RS Admin Pages hub. Switch the current root to **Admin** first. The hub returns 403 while a workspace is selected.
- `/admin/screens/pages` - page list (**New**, **Open**)
- `/recording_studio_pages/admin/pages` - redirects to the Admin list; editor stays under `/recording_studio_pages/admin/pages/:id`
- `/users/sign_in` - Users email-first sign-in
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` - dummy-only starter pages
- `/up` - Rails health check

## Why This App Exists

Use this app to verify page composition, publish, and public render before you copy the gem into another host. If a layout, route, asset source, or Recording Studio initializer change breaks here, the gem needs the same fix.
