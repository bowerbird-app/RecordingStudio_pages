# frozen_string_literal: true

# Dummy is the host. Public pages read this named theme; they do not hardcode it.
FlatPack.configure do |config|
  config.default_theme = :rounded
end
