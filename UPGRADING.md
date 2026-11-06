# Upgrading Recording Studio Pages

## 0.8.0

Bump to `0.8.0`. No Pages migration.

1. Install Pages `0.8.0`. Keep Recording Studio `>= 6.3.0` (dummy development pin `v6.5.0`) and FlatPack `>= 0.1.341`. Core 6.5.0 requires `config.authorize_write`. Dummy checks Accessible `:edit` on the recording being written (not a present actor).
2. Page Builder admin now fails closed: Accessible and Admin must be loaded, the access recording must resolve, and the actor must be Accessible-authorized on that recording. Missing Accessible used to allow the request.
3. The pages list and editor only load pages under roots the actor can `:view` (Accessible `root_recording_ids_for`). Creating a page parents it under a workspace (or other configured page parent) the actor can `:edit`. Saving still needs `:edit` on that page. Grant Accessible access on the content root as well as the Admin root. `:edit` on the Admin root with only `:view` on the page does not allow a save.
4. Dummy Admin stays `v2.9.1`. Hosts that follow the Admin 2.5.1 policy should not bump Admin from this gem. Users `v0.27.1` remains off-policy for Admin; this gem does not change that.

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
