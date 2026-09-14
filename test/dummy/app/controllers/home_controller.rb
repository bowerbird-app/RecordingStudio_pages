# frozen_string_literal: true

class HomeController < ApplicationController
  layout "flat_pack_sidebar"

  def index
    @admin_root_home = current_root_recording&.recordable_type == "AdminRoot"
  end
end
