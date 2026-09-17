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

    assert_includes admin, "link_to { |context| RecordingStudioPages::Admin.screen_path_for(context) }"
    assert_includes admin, "status: RecordingStudioPages::Composition::STATUS_DRAFT"
    assert_includes admin, "link_label \"Pages\""
    assert_includes admin, "link_label \"Drafts\""
  end

  def test_pages_screen_filters_by_live_or_draft_status
    admin = File.read(File.expand_path("../lib/recording_studio_pages/admin.rb", __dir__))

    assert_includes admin, "filter :status"
    assert_includes admin, "RecordingStudioPages::Composition::STATUS_OPTIONS"
    assert_includes admin, "filter_page_recordings_by_status"
    assert_includes admin, "column :status"
  end

  def test_screen_path_can_apply_a_draft_status_filter
    admin = File.read(File.expand_path("../lib/recording_studio_pages/admin.rb", __dir__))

    assert_includes admin, "def self.screen_path(status: nil)"
    assert_includes admin, "def self.screen_path_for(context, status: nil)"
    assert_includes admin, "query = { status: status }.to_query"
  end
end
