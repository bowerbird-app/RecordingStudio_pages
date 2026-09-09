# frozen_string_literal: true

require_relative "lib/recording_studio_pages/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_pages"
  spec.version     = RecordingStudioPages::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_pages"
  spec.summary     = "Compose public pages from Recording Studio recordings"
  spec.description = "A Recording Studio addon that treats pages and sections as recordings. " \
                     "Hosts register section types, compose them on a page, and publish with RS Publishable."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/RecordingStudio_pages"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/RecordingStudio_pages/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"].reject do |path|
      path == ".cursor" || path.start_with?(".cursor/")
    end
  end

  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", "~> 4.1"
  spec.add_dependency "view_component", ">= 3.0", "< 5.0"
end
