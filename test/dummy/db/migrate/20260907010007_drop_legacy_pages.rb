# frozen_string_literal: true

class DropLegacyPages < ActiveRecord::Migration[8.1]
  def change
    drop_table :pages, if_exists: true
  end
end
