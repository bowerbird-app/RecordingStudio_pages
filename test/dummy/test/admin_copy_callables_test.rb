# frozen_string_literal: true

require "test_helper"

# Prove RecordingStudio Admin evaluates Pages DSL callables at the arity we use
# (1-arg context for section/widget/link/button copy; 2-arg record+context for
# resource action text/confirm). Screen subtitle stays a plain string because
# Admin indexes it without evaluate.
class AdminCopyCallablesTest < ActiveSupport::TestCase
  setup do
    @context = Object.new
    @record = Object.new
  end

  test "admin section copy callables resolve english at arity one" do
    section = RecordingStudioPages::Admin::PagesSection

    assert_equal 1, section.title.arity
    assert_equal 1, section.subtitle.arity
    assert_equal "Pages", section.evaluate(section.title, @context)
    assert_equal "Compose public pages from registered sections",
                 section.evaluate(section.subtitle, @context)
    refute_match(/#<Proc/, section.evaluate(section.title, @context).to_s)
  end

  test "admin screen subtitle is a plain string for search indexing" do
    screen = RecordingStudioPages::Admin::PagesScreen

    assert_instance_of String, screen.subtitle
    assert_equal "Compose public pages from sections.", screen.subtitle
    assert_equal 1, screen.title.arity
    assert_equal "Pages", screen.evaluate(screen.title, @context)
    refute_match(/#<Proc/, screen.subtitle)
  end

  test "admin link and button text callables resolve english at arity one" do
    new_page = RecordingStudioPages::Admin::PagesSection.links.find { |link| link.name == :new_page }
    view_all = RecordingStudioPages::Admin::PagesSection.links.find { |link| link.name == :pages }
    button = Array(RecordingStudioPages::Admin::PagesScreen.buttons_value).find { |entry| entry.name == :new_page }

    assert new_page
    assert view_all
    assert button

    assert_equal 1, new_page.text.arity
    assert_equal 1, view_all.text.arity
    assert_equal 1, button.text.arity

    assert_equal "Page", new_page.text.call(@context)
    assert_equal "View all", view_all.text.call(@context)
    assert_equal "Page", button.text.call(@context)
  end

  test "admin widget copy callables resolve english at arity one" do
    published = RecordingStudioPages::Admin::PublishedPagesWidget
    drafts = RecordingStudioPages::Admin::DraftPagesWidget

    [
      [published, "@title", "Published"],
      [published, "@info", "Pages that are on the public site."],
      [published, "@link_label", "Published"],
      [drafts, "@title", "Drafts"],
      [drafts, "@info", "Pages that are still a draft."],
      [drafts, "@link_label", "Drafts"]
    ].each do |widget, ivar, english|
      value = widget.instance_variable_get(ivar)
      assert_equal 1, value.arity, "#{widget.key} #{ivar}"
      assert_equal english, widget.send(:evaluate, value, @context), "#{widget.key} #{ivar}"
      refute_match(/#<Proc/, widget.send(:evaluate, value, @context).to_s)
    end
  end

  test "admin resource action text and confirm resolve english at arity two" do
    edit = RecordingStudioPages::Admin::PagesResource.action_for(:edit)
    trash = RecordingStudioPages::Admin::PagesResource.action_for(:trash)

    assert_equal 2, edit.text.arity
    assert_equal 2, trash.text.arity
    assert_equal 2, trash.confirm.arity

    assert_equal "Edit", edit.send(:resolve_value, edit.text, @record, @context)
    assert_equal "Trash", trash.send(:resolve_value, trash.text, @record, @context)
    assert_equal "Trash this page?", trash.send(:resolve_value, trash.confirm, @record, @context)
  end
end
