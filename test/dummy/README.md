# Dummy App

This Rails app exists to validate the Recording Studio Page Builder in a real host application.

## What It Covers

- Recording Studio Users for sign-in, People, Profile, and Continue-with social buttons
- A seeded admin person (`admin@admin.com` / `Password`) with a Profile under the shared People root
- `Current.actor` wiring for Recording Studio events
- Workspace roots plus seeded page and section recordings
- Public homepage at `/` for visitors, from a published page recording. Dummy seed restores the sample Home template if sections drift. Home starts with a Menu (House, About, Tonight, Join), then a left-aligned hero. Signed-in people preview that same live page at `/site`.
- Signed-in `/` is the host home: a Flatpack sidebar, a root switcher in the top bar, and buttons to the live example pages. Switch to **Admin** in that switcher, then open **Admin** in the sidebar to reach `/admin`.
- Staff page composition at `/recording_studio_pages/admin/pages`. Add a section from the **Section** dropdown (plus icon). Use a template. The action row sits above the two columns: **Section**, **Use a template**, **Settings**, and Publishable’s Draft/Published control. Edit the section list in a padded Card in the first column and see enabled sections in the second. Empty columns use Flatpack Empty State (**Add your first section** and **Preview**). Open a section for **Update** and **Cancel** under the title, the form on the left, and a live preview on the right. Update stays on that section. Hero edit puts a **Call to action** divider above the CTA, then look under **Style**: **Align**, **Eyebrow**, **Headline** and **Subtitle** colours, and **Preset** (On a dark photo / On a light photo) only when the layout is a fullscreen picture. **Choose image** on hero, image-and-text, logo items, and rich text opens the Attachable picker for that section. Drag sections to reorder. Copy a section from the row’s three-dot menu (Recording Studio Duplicatable; photos come along). **Settings** opens rename, home, and remove. Dummy default layout keeps one `#flash` slot (`recording_studio_pages_flash`) on screens that include the Pages helper. RS Admin shares that layout and skips the slot. **Section** and Use a template replace that slot instead of stacking a second notice in the editor.
- RS Admin Pages section at `/admin`. Switch to the Admin root first. **Page** (plus icon, then the word Page) opens the new-page form. **View all** opens the Admin list of pages. That list also has **Page** with the plus icon, a **Status** filter (Draft, Scheduled, Published), a **Home page** filter, Publishable’s status control on each row, and an actions menu with Edit and Trash. The hub also lists **Users**. Dummy loads Turbo and RS Admin Stimulus so Published and Drafts leave the shimmer, show counts, and open the Pages list. Drafts opens that list with Draft selected. Dummy draws those hub buttons with Flatpack `href:` so they navigate.
- Recording Studio default layout, FlatPack assets (including `flat_pack/application`), and Tailwind source scanning via `tmp/tailwind` mirrors. Public pages use a full-width layout and the host Flatpack theme (`rounded` here). Users auth uses the gem's centered layout, not the dummy `max-w-md` application layout. Page builder screens use Recording Studio page nav (back and close). Signed-in dummy home uses a Flatpack sidebar and a root switcher. Dummy `/docs` still uses page nav with a root switcher and Sign out.
- Dummy-only `/docs/*` pages for host-app sandboxing

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

- `/` - visitors see the published homepage (seeded Home starts with a Menu). Signed-in people see the host home (sidebar, root switcher, example page buttons).
- `/site` - the live marketing homepage, even when you are signed in
- `/pages/:uuid/about` - seeded **About** page: a full-width rich text card with display type, Hero inset, and a corner picture
- `/pages/:uuid/join` - seeded **Join** page: one centered hero whose call to action is Users Continue-with buttons, centered under the copy
- `/pages/:uuid/walk-in` - seeded **Walk in** page: one fullscreen hero image (copy left on the photo) whose Continue-with buttons sit left with the copy
- `/pages/:uuid/start-from-a-url` - seeded **Start from a URL** page: one hero with a paste-a-link field and no field name
- `/start` - dummy catcher for that URL field
- `/studio` - same signed-in home as `/`
- `/recording_studio` - redirects to `/` while the mounted Recording Studio engine stays available under that prefix for non-root routes
- `/recording_studio_pages/admin/pages` - page builder
- `/recording_studio_users/profile` - My Profile
- `/admin` - RS Admin hub. Switch the current root to **Admin** first. **Page** goes to `/recording_studio_pages/admin/pages/new` (reading-width form, compact **Create page**). **View all** goes to `/admin/screens/pages`. Published and Drafts open that list; Drafts adds `status=Draft`, Published adds `status=Published`. The hub returns 403 while a workspace is selected. Published and Drafts load through Turbo frames; dummy pins Turbo and RS Admin Stimulus so those cards leave the shimmer.
- `/users/sign_in` - Users email-first sign-in
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` - dummy-only starter pages
- `/up` - Rails health check

## Why This App Exists

Use this app to verify page composition, publish, and public render before you copy the gem into another host. If a layout, route, asset source, or Recording Studio initializer change breaks here, the gem needs the same fix.
