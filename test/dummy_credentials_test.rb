# frozen_string_literal: true

require "test_helper"
require "yaml"
require "active_support/encrypted_file"

class DummyCredentialsTest < Minitest::Test
  PLACEHOLDER = "dev_placeholder"

  def test_only_dummy_credentials_files_are_committed
    tracked = Dir.chdir(File.expand_path("..", __dir__)) do
      `git ls-files -- '*.yml.enc'`.split("\n").reject(&:empty?)
    end

    assert_equal [
      "test/dummy/config/credentials.yml.enc",
      "test/dummy/config/credentials/development.yml.enc",
      "test/dummy/config/credentials/test.yml.enc"
    ].sort, tracked.sort
  end

  def test_encrypted_credentials_files_are_present
    dummy_credentials_paths.each do |path|
      assert File.exist?(path), "Expected #{path} so dummy credentials decrypt with the shared key"
      assert File.size(path).positive?
    end
  end

  def test_master_key_is_gitignored_and_untracked
    gitignore = File.read(File.expand_path("../.gitignore", __dir__))
    assert_includes gitignore, "test/dummy/config/master.key"
    assert_includes gitignore, "config/master.key"
    refute_includes gitignore, "!test/dummy/config/credentials/development.key"
    refute_includes gitignore, "!test/dummy/config/credentials/test.key"

    tracked = Dir.chdir(File.expand_path("..", __dir__)) do
      `git ls-files -- '*.key' config/master.key test/dummy/config/master.key`.strip
    end
    assert_equal "", tracked, "master.key and env credential keys must not be committed"
  end

  def test_dummy_credentials_decrypt_when_master_key_is_available
    skip "Set RAILS_MASTER_KEY or test/dummy/config/master.key to the shared dummy key" unless master_key_available?

    dummy_credentials_paths.each do |path|
      parsed = YAML.safe_load(
        ActiveSupport::EncryptedFile.new(
          content_path: path,
          key_path: key_path_for(path),
          env_key: "RAILS_MASTER_KEY",
          raise_if_missing_key: true
        ).read
      )

      assert_operator parsed.fetch("secret_key_base").to_s.length, :>=, 64, path
      assert_equal PLACEHOLDER, parsed.dig("gem_template", "api_key"), path
      assert_equal PLACEHOLDER, parsed.dig("smtp", "user_name"), path
      assert_equal PLACEHOLDER, parsed.dig("smtp", "password"), path
      assert_equal PLACEHOLDER, parsed.dig("aws", "access_key_id"), path
      assert_equal PLACEHOLDER, parsed.dig("aws", "secret_access_key"), path
      assert_equal PLACEHOLDER, parsed.dig("omniauth", "google_oauth2", "client_id"), path
      assert_equal PLACEHOLDER, parsed.dig("omniauth", "google_oauth2", "client_secret"), path
      assert_equal PLACEHOLDER, parsed.dig("omniauth", "apple", "client_id"), path
      assert_equal PLACEHOLDER, parsed.dig("omniauth", "apple", "client_secret"), path
    end
  end

  private

  def dummy_credentials_paths
    [
      File.expand_path("../test/dummy/config/credentials.yml.enc", __dir__),
      File.expand_path("../test/dummy/config/credentials/development.yml.enc", __dir__),
      File.expand_path("../test/dummy/config/credentials/test.yml.enc", __dir__)
    ]
  end

  def dummy_master_key_path
    File.expand_path("../test/dummy/config/master.key", __dir__)
  end

  def key_path_for(content_path)
    if File.basename(File.dirname(content_path)) == "credentials" && File.basename(content_path) != "credentials.yml.enc"
      content_path.sub(/\.yml\.enc\z/, ".key")
    else
      dummy_master_key_path
    end
  end

  def master_key_available?
    ENV["RAILS_MASTER_KEY"].to_s.strip.present? || File.exist?(dummy_master_key_path)
  end
end
