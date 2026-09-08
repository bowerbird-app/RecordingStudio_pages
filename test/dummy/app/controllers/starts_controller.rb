# frozen_string_literal: true

class StartsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_recording_studio_root_resolution

  layout "recording_studio_pages/public"

  def show
    @url = params[:url].to_s.strip
  end
end
