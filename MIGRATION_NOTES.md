# Migration Notes

## 0.3.11 terms and privacy

Dummy installs Recording Studio Terms and Conditions `v0.7.3` and pins Users `v0.12.2`, Publishable `v0.3.1`, and Flatpack `v0.1.196`. Seeded Home footer links to the published Terms and Privacy Policy. Create-password agrees to both.

Hosts that want the same documents install the terms gem, run its migrations, register `RecordingStudioTermsAndConditions::Terms`, and enable Admin `section :terms`. Page Builder does not depend on that gem. Existing footer links stay as saved.

## 0.3.10 footer section

**Footer** is a built-in page section: a name, a note, and links. It is full width. Add it from **Section**. Nothing to run. Existing pages stay as they are until you add one.

## 0.3.9 sample feature pictures

Dummy Home features Pages, Pieces, and Reuse now include a picture under `test/dummy/public/images/`. Hosts do not need to run anything. Feature image fields are unchanged.

A feature picture fills the width of its card and meets the border. If you overrode the feature grid or feature component, render that picture in `card.media(aspect_ratio: "4/3", padding: :none)`.

## 0.3.8 child sections

Feature grids and logo clouds no longer store an `items` list. Each row is a child section (`feature` or `logo`). After you deploy this version, run once:

```ruby
RecordingStudioPages::Services::UpgradeNestedSections.call
```

That records one child per saved row, copies an item image onto that child, and clears `items`. Run it again and it leaves the tree alone. New saves do not write `items`.

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 4.x (`~> 4.1` in the gemspec; dummy GitHub tag `v4.2.2`)
- Accessible dummy tag `v0.9.1`, Attachable dummy tag `v0.5.1`, Users dummy tag `v0.12.2`, Publishable dummy tag `v0.3.1`, Root Switchable dummy tag `v0.5.0`
- Terms and Conditions dummy tag `v0.7.3`
- FlatPack dummy tag `v0.1.196`
- Public RubyGems and GitHub access for dependency installation

## Verification

Install both bundles and run the complete gem and dummy app test path:

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

Run the dummy app from its directory for browser verification:

```bash
cd test/dummy
bin/dev
```

Use the [FlatPack repository](https://github.com/bowerbird-app/flatpack) and the live FlatPack demo linked from the top-level README for current component documentation.
