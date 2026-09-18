# frozen_string_literal: true

require "test_helper"
require "json"

class RecordingStudioPagesTest < Minitest::Test
  def test_version_matches_release
    assert_equal "0.3.7", ::RecordingStudioPages::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioPages::Engine
  end

  def test_gemspec_pins_recording_studio_4_1
    gemspec = File.read(File.expand_path("../recording_studio_pages.gemspec", __dir__))

    assert_includes gemspec, 'spec.add_dependency "recording_studio", "~> 4.1"'
    assert_includes gemspec, "https://github.com/bowerbird-app/RecordingStudio_pages"
  end

  def test_gemspec_excludes_cursor_config
    spec = Gem::Specification.load(File.expand_path("../recording_studio_pages.gemspec", __dir__))
    cursor_files = spec.files.select { |path| path == ".cursor" || path.split("/").include?(".cursor") }

    assert_empty cursor_files, "gemspec must not package .cursor/ (got #{cursor_files.inspect})"
  end

  def test_cursor_environment_is_repo_managed_without_snapshot
    path = File.expand_path("../.cursor/environment.json", __dir__)
    json = JSON.parse(File.read(path))

    assert_equal "recording-studio-gem-template", json["name"]
    assert_equal ".cursor/install.sh", json["install"]
    assert_equal ".cursor/start.sh", json["start"]
    refute json.key?("snapshot"), "snapshot pins a Personal build and skips install"
    refute json.key?("agentCanUpdateSnapshot")
  end

  def test_cursor_install_still_fetches_skills
    install_script = File.read(File.expand_path("../.cursor/install.sh", __dir__))

    assert_includes install_script, "fetch-skills.sh"
  end

  def test_dummy_gemfile_pins_verified_github_tags
    gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.9.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_root_switchable", tag: "v0.5.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.5.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.3.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_orderable", tag: "v0.2.2"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_duplicatable", tag: "v0.4.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_admin", tag: "v2.0.2"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_users", tag: "v0.11.0"'
    assert_includes gemfile, 'github: "bowerbird-app/flatpack", tag: "v0.1.186"'
    refute_includes gemfile, "recording_studio/v3.0.0"
    refute_includes gemfile, 'tag: "v0.1.134"'
    refute_includes gemfile, 'tag: "0.3.5"'
  end

  def test_section_opts_into_duplicatable_and_attachable
    section_source = File.read(File.expand_path("../app/models/recording_studio_pages/section.rb", __dir__))
    service_source = File.read(File.expand_path("../lib/recording_studio_pages/services/duplicate_section.rb", __dir__))

    assert_includes section_source, "Capabilities::Duplicatable.to"
    assert_includes section_source, "Capabilities::Attachable.to"
    assert_includes section_source, "image/*"
    assert_includes service_source, "duplicate_in_place!"
    assert_includes service_source, "record_attachment_upload"
    refute_includes service_source, "AddSection.call"
  end

  def test_template_does_not_ship_copied_core_hooks_or_base_service
    refute File.exist?(File.expand_path("../lib/recording_studio_pages/hooks.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_pages/services/base_service.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_pages/services/example_service.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_pages/capabilities/example.rb", __dir__))
  end

  def test_dummy_app_uses_recording_studio_default_layout
    application_controller_path = File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
    controller_source = File.read(application_controller_path)
    home_controller_source = File.read(File.expand_path("dummy/app/controllers/home_controller.rb", __dir__))

    assert_includes controller_source, "include RecordingStudio::UsesDefaultLayout"
    assert_includes controller_source, '"recording_studio/default_layout"'
    assert_includes controller_source, "devise_controller? ? \"application\""
    refute_includes controller_source, "flat_pack_sidebar"
    assert_includes home_controller_source, 'layout "flat_pack_sidebar"'
    assert File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack_sidebar.html.erb", __dir__))
    assert File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__))
    assert File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack/_top_nav.html.erb", __dir__))
  end

  def test_dummy_does_not_put_host_chrome_on_gem_screens
    dummy_helper = File.read(File.expand_path("dummy/app/helpers/application_helper.rb", __dir__))
    gem_helper = File.read(File.expand_path("../app/helpers/recording_studio_pages/application_helper.rb", __dir__))

    refute_includes dummy_helper, "recording_studio_pages_page_nav"
    assert_includes dummy_helper, "dummy_page_nav"
    assert_includes dummy_helper, "dummy_href_from_root"
    assert_includes dummy_helper, "recording_studio_root_switch_dropdown"
    assert_includes dummy_helper, "Sign out"
    assert_includes gem_helper, "recording_studio_page_nav"
    assert_includes gem_helper, "page_nav_anchor_url"
    assert_includes gem_helper, "pages_nav_anchor_url"
  end

  def test_dummy_login_layout_keeps_flatpack_assets_without_tight_main_offset
    application_layout = File.read(File.expand_path("dummy/app/views/layouts/application.html.erb", __dir__))

    assert_includes application_layout, "RecordingStudioPages.theme"
    refute_includes application_layout, 'data-theme="rounded"'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/application"'
    assert_includes application_layout, "javascript_importmap_tags"
    assert_includes application_layout, "min-h-screen"
    refute_includes application_layout, "mt-28"
    refute_includes application_layout, "flat_pack_sidebar"
  end

  def test_public_layout_loads_flatpack_without_the_sign_in_column
    layout = File.read(File.expand_path("../app/views/layouts/recording_studio_pages/public.html.erb", __dir__))

    assert_includes layout, '<html data-theme="<%= RecordingStudioPages.theme %>">'
    refute_includes layout, 'data-theme="rounded"'
    refute_includes layout, 'class="h-full"'
    assert_includes layout, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes layout, 'stylesheet_link_tag "flat_pack/application"'
    assert_includes layout, 'stylesheet_link_tag "tailwind"'
    assert_includes layout, "bg-(--surface-page-background-color)"
    assert_includes layout, "min-h-dvh"
    assert_includes layout, "viewport-fit=cover"
    assert_includes layout, "publishable_head_tags"
    assert_includes layout, "publishable_document_title"
    assert_includes layout, "publishable_preview_badge"
    refute_includes layout, "max-w-md"
    variables_at = layout.index('stylesheet_link_tag "flat_pack/variables"')
    tailwind_at = layout.index('stylesheet_link_tag "tailwind"')
    assert_operator variables_at, :<, tailwind_at
  end

  def test_dummy_tailwind_keeps_flatpack_theme_selection_in_flatpack
    tailwind_source = File.read(File.expand_path("dummy/app/assets/tailwind/application.css", __dir__))

    assert_includes tailwind_source, "tmp/tailwind/flat_pack_components/**/*.rb"
    assert_includes tailwind_source, "tmp/tailwind/flat_pack_components/**/*.erb"
    assert_includes tailwind_source, "tmp/tailwind/recording_studio_user_views/**/*.erb"
    assert_includes tailwind_source, "RecordingStudio-*/app/views/**/*.erb"
    assert_includes tailwind_source, "RecordingStudio_users-*/app/views/**/*.erb"
    assert_includes tailwind_source, "../../../../../app/components/**/*.rb"
    assert_includes tailwind_source, "../../../../../app/components/**/*.erb"
    assert_includes tailwind_source, "../../components/**/*.rb"
    refute_includes tailwind_source, "@theme"
    refute_includes tailwind_source, ":root {"
    refute_includes tailwind_source, "--color-fp-primary"
    refute_includes tailwind_source, "{rb,erb}"
  end

  def test_dummy_default_layout_loads_flatpack_application_on_html_theme
    layout = File.read(File.expand_path("dummy/app/views/layouts/recording_studio/default_layout.html.erb", __dir__))

    assert_includes layout, '<html data-theme="<%= RecordingStudioPages.theme %>">'
    refute_includes layout, 'data-theme="rounded"'
    assert_includes layout, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes layout, 'stylesheet_link_tag "flat_pack/application"'
    assert_includes layout, 'stylesheet_link_tag "tailwind"'
    assert_includes layout, "max-w-6xl"
    assert_includes layout, "recording_studio_pages_flash if respond_to?(:recording_studio_pages_flash)"
    assert_includes layout, "page_nav_options[:anchor_href] = anchor_url"
    refute_includes layout, "page_nav_options[:anchor_url] = anchor_url"
    refute_includes layout, "page_nav_options[:back_url] = back_url"
    refute_includes layout, "flash[:notice]"
    refute_includes layout, "flash[:alert]"
    variables_at = layout.index('stylesheet_link_tag "flat_pack/variables"')
    tailwind_at = layout.index('stylesheet_link_tag "tailwind"')
    assert_operator variables_at, :<, tailwind_at
  end

  def test_recording_studio_keeps_strict_recordable_declarations_enabled
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "config.require_recordable_declarations = true"
    assert_includes initializer_source, "RecordingStudioPages::Page"
    assert_includes initializer_source, "RecordingStudioPages::Section"
    assert_includes initializer_source, "RecordingStudioUser::People"
    assert_includes initializer_source, "RecordingStudioUser::Profile"
    refute_includes initializer_source, "config.include_children"
    refute_includes initializer_source, "config.features."
    refute_includes initializer_source, "v3"
  end

  def test_dummy_sets_the_host_flatpack_theme
    initializer = File.read(File.expand_path("dummy/config/initializers/flat_pack.rb", __dir__))

    assert_includes initializer, "FlatPack.configure"
    assert_includes initializer, "default_theme = :rounded"
  end

  def test_dummy_readme_explains_dummy_app_purpose
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "Page Builder"
    assert_includes readme_source, "/recording_studio"
    assert_includes readme_source, "sidebar"
    assert_includes readme_source, "/site"
    assert_includes readme_source, "recording_studio_pages_flash"
  end

  def test_product_readme_is_the_page_builder_guide
    readme = File.read(File.expand_path("../README.md", __dir__))

    assert_includes readme, "RecordingStudioPages"
    assert_includes readme, "register_section"
    assert_includes readme, "register_cta"
    assert_includes readme, "recording_studio_pages_flash"
    assert_includes readme, "RS Publishable"
    refute_includes readme, "internal template"
    refute_includes readme, "ExampleService"
    refute_includes readme, "v3 declarations"
  end

  def test_dummy_studio_page_uses_example_page_buttons
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)
    routes = File.read(File.expand_path("dummy/config/routes.rb", __dir__))
    helper = File.read(File.expand_path("dummy/app/helpers/application_helper.rb", __dir__))
    top_nav = File.read(File.expand_path("dummy/app/views/layouts/flat_pack/_top_nav.html.erb", __dir__))
    sidebar = File.read(File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__))

    assert_includes view_source, "dummy_example_pages"
    assert_includes view_source, "FlatPack::Button::Component"
    assert_includes view_source, "current_root_recordable"
    refute_includes view_source, "dummy_page_nav"
    refute_includes view_source, "FlatPack::Card::Component"
    refute_includes view_source, 'title: "Page Builder studio"'
    assert_includes helper, "dummy_example_pages"
    assert_includes helper, '"/site"'
    assert_includes top_nav, "recording_studio_root_switch_dropdown"
    assert_includes sidebar, 'text: "Admin"'
    assert_includes routes, 'root to: "home#index"'
    assert_includes routes, 'root to: "recording_studio_pages/homepages#show"'
    assert_includes routes, 'get "/site"'
  end

  def test_dummy_docs_pages_use_minimal_flatpack_documentation_components
    docs_view_paths = Dir[File.expand_path("dummy/app/views/docs/*.html.erb", __dir__)].reject do |view_path|
      File.basename(view_path).start_with?("_")
    end
    refute_empty docs_view_paths

    docs_view_paths.each do |view_path|
      view_source = File.read(view_path)

      assert_includes view_source, "dummy_page_nav"
      assert_includes view_source, "FlatPack::PageTitle::Component"
      refute_includes view_source, "FlatPack::Card::Component"
      refute_includes view_source, "FlatPack::Breadcrumb::Component"
    end

    methods_view = File.read(File.expand_path("dummy/app/views/docs/methods.html.erb", __dir__))
    assert_includes methods_view, "FlatPack::SectionTitle::Component"
    assert_includes methods_view, "FlatPack::CodeBlock::Component"

    gem_views_view = File.read(File.expand_path("dummy/app/views/docs/gem_views.html.erb", __dir__))
    assert_includes gem_views_view, "FlatPack::Table::Component"
    refute_includes gem_views_view, "FlatPack::List::Component"

    recordable_types_view = File.read(File.expand_path("dummy/app/views/docs/recordable_types.html.erb", __dir__))
    assert_includes recordable_types_view, "FlatPack::List::Component"
    refute_includes recordable_types_view, "v3 parent/root"

    recordings_tree_view = File.read(File.expand_path("dummy/app/views/docs/recordings_tree.html.erb", __dir__))
    assert_includes recordings_tree_view, "FlatPack::Tree::Component"
    refute_includes recordings_tree_view, "Current structure"
    refute_includes recordings_tree_view, "This tree is generated from RecordingStudio::Recording records"
  end

  def test_dummy_recordings_tree_view_omits_structure_section_copy
    recordings_tree_view = File.read(File.expand_path("dummy/app/views/docs/recordings_tree.html.erb", __dir__))

    assert_includes recordings_tree_view, 'title: "Recordings tree"'
    assert_includes recordings_tree_view, "FlatPack::Tree::Component"
    recording_tree_partial = File.read(File.expand_path("dummy/app/views/docs/_recording_tree_node.html.erb", __dir__))
    assert_includes recording_tree_partial, "parent_builder.node"
    refute_includes recordings_tree_view, "Current structure"
    refute_includes recordings_tree_view, "This tree is generated from RecordingStudio::Recording records"
  end

  def test_engine_does_not_ship_a_home_view
    view_path = File.expand_path("../app/views/recording_studio_pages/home/index.html.erb", __dir__)

    refute File.exist?(view_path)
  end

  def test_gem_admin_views_use_engine_nav_not_dummy_nav
    views = Dir[File.expand_path("../app/views/recording_studio_pages/**/*.erb", __dir__)]
    refute_empty views

    views.each do |view_path|
      source = File.read(view_path)

      refute_includes source, "dummy_page_nav", "#{view_path} must not call dummy_page_nav"
    end

    editor = File.read(File.expand_path("../app/views/recording_studio_pages/admin/pages/_editor.html.erb", __dir__))
    index = File.read(File.expand_path("../app/views/recording_studio_pages/admin/pages/index.html.erb", __dir__))
    edit = File.read(File.expand_path("../app/views/recording_studio_pages/admin/pages/edit.html.erb", __dir__))
    template_dropdown = File.read(
      File.expand_path("../app/views/recording_studio_pages/admin/pages/_add_template_dropdown.html.erb", __dir__)
    )

    assert_includes editor, "orderable_url:"
    assert_includes editor, "add_template_dropdown"
    assert_includes editor, "FlatPack::Grid::Component.new(cols: 2"
    assert_includes editor, "FlatPack::Card::Component.new(padding: :md)"
    assert_includes editor, "FlatPack::EmptyState::Component"
    assert_includes editor, 'title: "Add your first section"'
    assert_includes editor, 'title: "Preview"'
    assert_includes editor, 'text: "Settings"'
    assert_includes editor, "render_publishable_quick_actions"
    assert_operator editor.index('text: "Settings"'), :<, editor.index("FlatPack::Grid::Component.new(cols: 2")
    refute_includes editor, 'text: "Publish"'
    refute_includes editor, "/publishable/edit"
    refute_includes editor, "padding: :none"
    refute_includes editor, 'text: "Edit page"'
    refute_includes editor, "Off sections stay off"
    refute_includes editor, "editor_notice"
    refute_includes editor, "local_assigns[:notice]"
    refute_includes editor, "Nothing live yet"
    refute_includes editor, "Nothing here yet"
    assert_includes template_dropdown, "Use a template"
    assert_includes template_dropdown, "turbo_stream: true"
    refute_includes template_dropdown, 'turbo_frame: "page_editor"'

    add_section_dropdown = File.read(
      File.expand_path("../app/views/recording_studio_pages/admin/pages/_add_section_dropdown.html.erb", __dir__)
    )
    assert_includes add_section_dropdown, "turbo_stream: true"
    assert_includes add_section_dropdown, 'text: "Section"'
    assert_includes add_section_dropdown, 'icon: "plus"'
    refute_includes add_section_dropdown, "Add section"
    refute_includes add_section_dropdown, 'turbo_frame: "page_editor"'

    flash_partial = File.read(File.expand_path("../app/views/recording_studio_pages/_flash.html.erb", __dir__))
    assert_includes flash_partial, 'id="flash"'
    assert_includes flash_partial, "flash[:alert]"
    assert_includes flash_partial, "flash[:notice]"
    assert_includes flash_partial, "elsif flash[:notice]"

    helper = File.read(File.expand_path("../app/helpers/recording_studio_pages/application_helper.rb", __dir__))
    assert_includes helper, "def recording_studio_pages_flash"

    dummy_helper = File.read(File.expand_path("dummy/app/helpers/application_helper.rb", __dir__))
    assert_includes dummy_helper, "include RecordingStudioPages::ApplicationHelper"

    create_stream = File.read(
      File.expand_path("../app/views/recording_studio_pages/admin/sections/create.turbo_stream.erb", __dir__)
    )
    apply_stream = File.read(
      File.expand_path("../app/views/recording_studio_pages/admin/pages/apply_template.turbo_stream.erb", __dir__)
    )
    [create_stream, apply_stream].each do |stream|
      assert_includes stream, 'turbo_stream.replace "flash"'
      assert_includes stream, 'turbo_stream.update "page_editor"'
      refute_includes stream, "notice:"
    end

    section_edit = File.read(
      File.expand_path("../app/views/recording_studio_pages/admin/sections/edit.html.erb", __dir__)
    )
    assert_includes section_edit, "FlatPack::Grid::Component.new(cols: 2"
    assert_includes section_edit, "recording_studio_pages/pages/section"
    refute_includes section_edit, 'title: "Preview"'
    assert_includes section_edit, 'title: "Nothing to preview"'
    assert_includes section_edit, 'text: "Update"'
    assert_includes section_edit, 'text: "Cancel"'
    assert_includes section_edit, "style: :default"
    assert_includes section_edit, "flex-wrap items-center gap-3"
    assert_includes section_edit, "form: section_form_id"
    assert_includes section_edit, "turbo: false"
    form = File.read(File.expand_path("../app/views/recording_studio_pages/admin/sections/_form.html.erb", __dir__))
    refute_includes form, "Save section"
    refute_includes form, 'text: "Update"'
    assert_includes form, "form_with"
    assert_includes form, "novalidate: true"
    assert_includes form, 'label: "Style"'
    assert_includes form, 'label: "Call to action"'
    assert_includes form, 'spec[:type].to_s == "cta"'
    assert_includes form, "style-fields"
    controller = File.read(
      File.expand_path("../app/controllers/recording_studio_pages/admin/sections_controller.rb", __dir__)
    )
    assert_includes controller, "edit_admin_page_section_path"
    assert_includes controller, 'notice: "Updated."'
    refute_includes controller, "Section saved."
    assert_includes controller, "flash.now[:notice] = added_notice"
    refute_includes controller, "helper_method :added_notice"

    pages_controller = File.read(
      File.expand_path("../app/controllers/recording_studio_pages/admin/pages_controller.rb", __dir__)
    )
    assert_includes pages_controller, 'flash.now[:notice] = "Template sections added."'

    section_row = File.read(
      File.expand_path("../app/views/recording_studio_pages/admin/pages/_section_row.html.erb", __dir__)
    )
    section_actions = File.read(
      File.expand_path("../app/views/recording_studio_pages/admin/pages/_section_actions.html.erb", __dir__)
    )
    refute_includes section_row, "subtitle"
    refute_includes section_row, "preview"
    refute_includes section_row, "leading:"
    assert_includes section_actions, 'icon: "ellipsis-horizontal"'
    assert_includes section_actions, "show_chevron: false"
    refute_includes section_actions, 'text: "More"'

    list_js = File.read(File.expand_path("../app/javascript/recording_studio_pages/controllers/section_list_controller.js", __dir__))
    refute_includes list_js, "persist"
    refute_includes list_js, "moving_recording_id"
    assert_includes list_js, "list:error"

    append = File.read(File.expand_path("../lib/recording_studio_pages/services/append_section_order.rb", __dir__))
    assert_includes append, "recording_studio_orderable_append!"
    refute_includes append, "recording_studio_orderable_move!"
    assert_includes index, "description:"
    refute_includes index, "message:"
    assert_includes index, 'text: "Page"'
    assert_includes index, 'icon: "plus"'
    refute_includes index, "New page"
    new_page = File.read(File.expand_path("../app/views/recording_studio_pages/admin/pages/new.html.erb", __dir__))
    assert_includes new_page, "max-w-xl"
    assert_includes new_page, "flex-wrap items-center gap-3"
    assert_includes new_page, "anchor_url: RecordingStudioPages::Admin.admin_mount_path"
    create_page = File.read(File.expand_path("../lib/recording_studio_pages/services/create_page.rb", __dir__))
    assert_includes create_page, "page.homepage = homepage?"
    controller = File.read(
      File.expand_path("../app/controllers/recording_studio_pages/admin/pages_controller.rb", __dir__)
    )
    assert_includes controller, "def checked?"
    assert_includes controller, "ActiveModel::Type::Boolean.new.cast(value) == true"
    base_controller = File.read(
      File.expand_path("../app/controllers/recording_studio_pages/admin/base_controller.rb", __dir__)
    )
    assert_includes base_controller, "def default_url_options"
    assert_includes base_controller, "safe_anchor_url(params[:anchor_url])"
    dummy_section = File.read(
      File.expand_path("dummy/app/views/recording_studio_admin/sections/show.html.erb", __dir__)
    )
    dummy_screen = File.read(
      File.expand_path("dummy/app/views/recording_studio_admin/screens/show.html.erb", __dir__)
    )
    assert_includes dummy_section, "href: preserve_anchor_url(link.url)"
    refute_includes dummy_section, "url: preserve_anchor_url(link.url)"
    assert_includes dummy_screen, "href: preserve_anchor_url(button.url)"
    refute_includes dummy_screen, "href: button.url"
    assert_includes dummy_screen, 'icon: (button.name.to_s == "new_page" ? "plus" : nil)'
    assert_includes dummy_screen, "page_title.slot"
    refute_includes dummy_screen, "recording_studio_page_nav_right"
    assert_includes edit, "Remove page"
    assert_includes edit, 'title: "Settings"'
    refute_includes edit, "Edit page"

    page_model = File.read(File.expand_path("../app/models/recording_studio_pages/page.rb", __dir__))
    assert_includes page_model, "respond_to?(:page_parent_types)"
    assert_includes page_model, 'public_layout: "recording_studio_pages/public"'

    hero = File.read(File.expand_path("../app/components/recording_studio_pages/sections/hero_component.rb", __dir__))
    assert_includes hero, "--hero-overlay-min-height: 100dvh"
    assert_includes hero, "align:"
    assert_includes hero, "overlay_on"
    assert_includes hero, "--hero-overlay-text-color"
    assert_includes hero, "--surface-content-color"
    assert_includes hero, "eyebrow_color"
    assert_includes hero, "title_color"
    assert_includes hero, "body_color"
    assert_includes hero, "coloured_line"
    refute_includes hero, "--hero-overlay-muted-text-color"
    refute_includes hero, "--surface-muted-content-color"
    assert_includes hero, "CtaRenderer"
    assert_includes hero, "align: align"
    assert_includes hero, 'content["image"]'
    refute_includes hero, "h-dvh"
    refute_includes hero, '"h-full"'
    refute_includes hero, "h-screen"
    refute_includes hero, 'content["image_url"]'

    top_nav = File.read(
      File.expand_path("../app/components/recording_studio_pages/sections/top_nav_component.rb", __dir__)
    )
    section_partial = File.read(
      File.expand_path("../app/views/recording_studio_pages/pages/_section.html.erb", __dir__)
    )
    dummy_js = File.read(File.expand_path("dummy/app/javascript/controllers/index.js", __dir__))
    dummy_application_js = File.read(File.expand_path("dummy/app/javascript/application.js", __dir__))
    dummy_importmap = File.read(File.expand_path("dummy/config/importmap.rb", __dir__))
    assert_includes top_nav, "FlatPack::TopNav"
    assert_includes top_nav, "CtaRenderer"
    assert_includes top_nav, "homepage_path"
    refute_includes top_nav, "recording_studio_navigation"
    assert_includes section_partial, "full_bleed?"
    refute_includes section_partial, 'key == "hero"'
    assert_includes dummy_js, 'lazyLoadControllersFrom("controllers/flat_pack"'
    assert_includes dummy_application_js, 'import "@hotwired/turbo-rails"'
    assert_includes dummy_importmap, 'pin "@hotwired/turbo-rails"'
    assert_includes dummy_importmap, "controllers/recording_studio_admin"

    rich_text = File.read(
      File.expand_path("../app/components/recording_studio_pages/sections/rich_text_component.rb", __dir__)
    )
    assert_includes rich_text, "px-16 py-24"
    assert_includes rich_text, "pt-24 pb-56"
    assert_includes rich_text, "--text-5xl"
    assert_includes rich_text, "--text-2xl"
    assert_includes rich_text, "max-w-xl"
    assert_includes rich_text, 'content["image"]'
    assert_includes rich_text, "object-contain"
    refute_includes rich_text, "padding: :lg"
    refute_includes rich_text, "PageTitle"

    cta_js = File.read(File.expand_path("../app/javascript/recording_studio_pages/controllers/cta_fields_controller.js", __dir__))
    assert_includes cta_js, "panelTargets"
    assert_includes cta_js, "field.disabled"
    dummy_initializer = File.read(File.expand_path("dummy/config/initializers/recording_studio_pages.rb", __dir__))
    assert_includes dummy_initializer, "register_cta"
    assert_includes dummy_initializer, ":social_logins"
    assert_includes dummy_initializer, ":url_form"
    assert_includes dummy_initializer, "key: :walk_in"
    assert_includes dummy_initializer, 'type: "social_logins"'
    assert_includes dummy_initializer, "fullscreen_image"
    social = File.read(File.expand_path("dummy/app/components/dummy/ctas/social_logins_component.rb", __dir__))
    url_form = File.read(File.expand_path("dummy/app/components/dummy/ctas/url_form_component.rb", __dir__))
    assert_includes social, "recording_studio_user_omniauth_provider_names"
    assert_includes social, "recording_studio_user_omniauth_authorize_path"
    assert_includes social, "max-w-sm"
    assert_includes social, "mr-auto"
    assert_includes social, "mx-auto"
    refute_includes social, "recording_studio_user/omniauth/continue_with_providers"
    refute_includes social, "/users/sign_in"
    refute_includes url_form, 'label: "Link"'
    assert_includes url_form, "sm:items-center"
    assert_includes url_form, 'aria: { label: "Paste a link" }'
    field = File.read(File.expand_path("../app/views/recording_studio_pages/admin/sections/_field.html.erb", __dir__))
    attachment_field = File.read(
      File.expand_path("../app/views/recording_studio_pages/admin/sections/_attachment_field.html.erb", __dir__)
    )
    built_ins = File.read(File.expand_path("../lib/recording_studio_pages/built_ins.rb", __dir__))
    assert_includes field, ":attachment"
    assert_includes field, ":color"
    assert_includes field, "ColorSwatch"
    assert_includes attachment_field, "Choose image"
    assert_includes attachment_field, "recording-studio-attachable--attachment-image-picker"
    refute_includes attachment_field, "Image url"
    assert_includes built_ins, "type: :attachment"
    assert_includes built_ins, "key: :top_nav"
    assert_includes built_ins, "name: \"Menu\""
    assert_includes built_ins, "full_bleed: true"
    assert_includes built_ins, 'label: "Preset"'
    assert_includes built_ins, "On a dark photo"
    assert_includes built_ins, "group: :style"
    assert_includes built_ins, 'label: "Eyebrow"'
    assert_includes built_ins, 'label: "Subtitle"'
    refute_includes built_ins, "Quieter line"
    refute_includes built_ins, 'label: "Photo"'
    refute_includes built_ins, "image_url:"
    engine = File.read(File.expand_path("../lib/recording_studio_pages/engine.rb", __dir__))
    pages_controller = File.read(
      File.expand_path("../app/controllers/recording_studio_pages/application_controller.rb", __dir__)
    )
    homepage_controller = File.read(
      File.expand_path("../app/controllers/recording_studio_pages/homepages_controller.rb", __dir__)
    )
    admin_base = File.read(
      File.expand_path("../app/controllers/recording_studio_pages/admin/base_controller.rb", __dir__)
    )
    assert_includes engine, "restore_registries!"
    assert_includes engine, "helper RecordingStudioPages::ApplicationHelper"
    assert_includes pages_controller, "helper RecordingStudioPublishable::ApplicationHelper"
    assert_includes homepage_controller, "assign_publishable"
    refute_includes admin_base, "Not public yet."
    attachment_js = File.read(
      File.expand_path("../app/javascript/recording_studio_pages/controllers/attachment_field_controller.js", __dir__)
    )
    style_js = File.read(
      File.expand_path("../app/javascript/recording_studio_pages/controllers/style_fields_controller.js", __dir__)
    )
    assert_includes attachment_js, "attachment.id"
    assert_includes style_js, "gatedTargets"
    assert_includes style_js, "fullscreen_image"
  end
end
