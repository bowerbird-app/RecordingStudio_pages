# frozen_string_literal: true

require "test_helper"

class AdminSectionTest < Minitest::Test
  def test_pages_section_puts_the_primary_page_action_first
    admin = File.read(File.expand_path("../lib/recording_studio_pages/admin.rb", __dir__))
    new_page = admin.index("link :new_page")
    view_all = admin.index("link :pages")

    assert_operator new_page, :<, view_all
    assert_includes admin, "text: \"Page\""
    assert_includes admin, "style: :primary"
    assert_includes admin, "text: \"View all\""
    assert_includes admin, "style: :secondary"
    refute_includes admin, "View pages"
    refute_includes admin, "New page"
  end

  def test_pages_hub_links_go_to_the_admin_list_and_new_page
    admin = File.read(File.expand_path("../lib/recording_studio_pages/admin.rb", __dir__))

    assert_includes admin, "context.admin_screen_path(SCREEN_KEY)"
    assert_includes admin, "RecordingStudioPages::Admin.new_page_path"
    assert_includes admin, "ENGINE_MOUNT_PATH = \"/recording_studio_pages\""
    assert_includes admin, "sortable: false"
    assert_includes admin, "default_sort :updated_at"
    assert_includes admin, "value: ->(recording, _context)"
  end

  def test_hub_widgets_link_to_the_pages_screen
    admin = File.read(File.expand_path("../lib/recording_studio_pages/admin.rb", __dir__))

    assert_includes admin, "status: RecordingStudioPages::Composition::STATUS_PUBLISHED"
    assert_includes admin, "status: RecordingStudioPages::Composition::STATUS_DRAFT"
    assert_includes admin, "link_label \"Published\""
    assert_includes admin, "link_label \"Drafts\""
    refute_includes admin, "Live pages"
  end

  def test_pages_screen_filters_by_publishable_status_and_home
    admin = File.read(File.expand_path("../lib/recording_studio_pages/admin.rb", __dir__))

    assert_includes admin, "filter :status"
    assert_includes admin, "RecordingStudioPages::Composition::STATUS_OPTIONS"
    assert_includes admin, "filter_page_recordings_by_status"
    assert_includes admin, "column :status"
    assert_includes admin, "render_publishable_actions"
    assert_includes admin, "render_publishable_quick_actions"
    assert_includes admin, "filter :homepage"
    assert_includes admin, "filter_page_recordings_by_homepage"
    assert_includes admin, "admin_action SCREEN_KEY, :edit"
    assert_includes admin, "admin_action SCREEN_KEY, :trash"
  end

  def test_row_actions_edit_and_trash_the_page
    admin = File.read(File.expand_path("../lib/recording_studio_pages/admin.rb", __dir__))

    assert_includes admin, "action :edit"
    assert_includes admin, "text: \"Edit\""
    assert_includes admin, "action :trash"
    assert_includes admin, "text: \"Trash\""
    assert_includes admin, "confirm: \"Trash this page?\""
    assert_includes admin, "method: :delete"
    assert_includes admin, "required_role: :edit"
    refute_includes admin, "action :open"
  end

  def test_admin_installs_publishable_helpers_on_the_isolated_engine
    admin = File.read(File.expand_path("../lib/recording_studio_pages/admin.rb", __dir__))
    engine = File.read(File.expand_path("../lib/recording_studio_pages/engine.rb", __dir__))

    assert_includes admin, "helper RecordingStudioPublishable::ApplicationHelper"
    assert_includes admin, "Rails.application.routes.mounted_helpers"
    assert_includes engine, "RecordingStudioPages::Admin.install_helpers!"
  end

  def test_screen_path_can_apply_status_and_home_filters
    admin = File.read(File.expand_path("../lib/recording_studio_pages/admin.rb", __dir__))

    assert_includes admin, "def self.screen_path(status: nil, homepage: nil)"
    assert_includes admin, "def self.screen_path_for(context, status: nil, homepage: nil)"
    assert_includes admin, "query.to_query"
  end
end
