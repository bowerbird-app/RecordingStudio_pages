# frozen_string_literal: true

class HomeController < ApplicationController
  # Dummy host chrome: sidebar + root switcher. Product surfaces keep
  # recording_studio/default_layout via ApplicationController.
  layout "flat_pack_sidebar"

  def index
  end
end
