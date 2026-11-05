# Upgrading Recording Studio Pages

## 0.7.0

Bump to `0.7.0` with Recording Studio `>= 6.3.0` and FlatPack `>= 0.1.341`. No Pages migration.

1. Replace `include RecordingStudio::UsesDefaultLayout` and `layout "recording_studio/default_layout"` with `recording_studio_layout`. Engine controllers already call `recording_studio_layout { RecordingStudioPages.configuration.layout }`.
2. Leave `config.layout` unset to use `RecordingStudio.configuration.layout`, then `recording_studio/default_layout`. `false` skips the layout. A callable must take `controller:` and return a String, `nil`, or `false`.
3. Public homepage and published pages still use `recording_studio_pages/public`. Do not put those screens on Default Layout.
4. Rebuild Tailwind so Default Layout and FlatPack 0.1.341 classes are in the host CSS. Cards no longer take `style:`. TopNav no longer takes `mobile_menu_label`. PageNav constructor kwargs are gone; use `flat_pack_page_nav` with `with_back` / `with_close` only if you construct the component yourself.
5. Pin FlatPack `v0.1.341` (or later). Do not pin `view_component` to close GHSA-8qw7-6phv-7q6p; that floor arrives through FlatPack.
6. Terms is not in the dummy. Latest Terms tag `v0.14.2` still requires `recording_studio ~> 4.2`. Keep Terms in a host only after that gem allows 6.3.
7. Admin `2.9.1` is fail-closed: missing access is forbidden, and Admin exports need `recording_studio_admin` in Exportable `trusted_export_sources`.
8. Attachable `0.22` signs blob ids with purpose `:attachable_upload`. Pages copies section images through `ImportAttachment` instead of a bare `signed_id`.
