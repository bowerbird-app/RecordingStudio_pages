# frozen_string_literal: true

module RecordingStudioPages
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioPages

    initializer "recording_studio_pages.assets" do |app|
      app.config.assets.paths << root.join("app/javascript") if app.config.respond_to?(:assets)
    end

    initializer "recording_studio_pages.importmap", before: "importmap" do |app|
      next unless app.config.respond_to?(:importmap)

      app.config.importmap.paths << root.join("config/importmap.rb")
    end

    initializer "recording_studio_pages.optional_dependencies", before: :set_routes_reloader do
      %w[
        recording_studio_accessible
        recording_studio_attachable
        recording_studio_publishable
        recording_studio_orderable
        recording_studio_admin
      ].each do |name|
        require name
      rescue LoadError
        next
      end
      require "recording_studio_pages/admin" if defined?(RecordingStudioAdmin)
    end

    config.to_prepare do
      RecordingStudioPages.reset!
      RecordingStudioPages::BuiltIns.register! if RecordingStudioPages.configuration.register_built_in_sections
      RecordingStudioPages.configuration.hooks.run(:register_sections, RecordingStudioPages)
      RecordingStudioPages::Admin.register! if defined?(RecordingStudioPages::Admin) && defined?(RecordingStudioAdmin)
    end

    class << self
      def apply_model_extensions(target)
        apply_extensions(target, extensions_for(:model, extension_keys_for(target)))
      end

      def apply_controller_extensions(target)
        apply_extensions(target, extensions_for(:controller, extension_keys_for(target)))
      end

      private

      def extensions_for(kind, names)
        hooks = RecordingStudioPages.configuration.hooks
        Array(names).flat_map do |name|
          if kind == :model
            hooks.model_extensions_for(name)
          else
            hooks.controller_extensions_for(name)
          end
        end
      end

      def apply_extensions(target, extensions)
        return unless target

        applied = target.instance_variable_get(:@recording_studio_pages_applied_extensions) || identity_hash

        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        target.instance_variable_set(:@recording_studio_pages_applied_extensions, applied)
      end

      def extension_keys_for(target)
        names = [target.name, target.name&.demodulize].compact.uniq
        names.map(&:to_sym)
      end

      def identity_hash
        {}.compare_by_identity
      end
    end

    # Run before_initialize hooks
    initializer "recording_studio_pages.before_initialize", before: "recording_studio_pages.load_config" do |_app|
      RecordingStudioPages.configuration.hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_pages.load_config" do |app|
      # Load config/recording_studio_pages.yml via Rails config_for if present
      if app.respond_to?(:config_for)
        begin
          yaml = begin
            app.config_for(:recording_studio_pages)
          rescue StandardError
            nil
          end
          RecordingStudioPages.configuration.merge!(yaml) if yaml.respond_to?(:each)
        rescue StandardError => _e
          # ignore load errors; host app can provide initializer overrides
        end
      end

      # Merge Rails.application.config.x.recording_studio_pages if present
      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_pages)
        xcfg = app.config.x.recording_studio_pages
        if xcfg.respond_to?(:to_h)
          RecordingStudioPages.configuration.merge!(xcfg.to_h)
        else
          begin
            # try converting OrderedOptions
            hash = {}
            xcfg.each_pair { |k, v| hash[k] = v } if xcfg.respond_to?(:each_pair)
            RecordingStudioPages.configuration.merge!(hash) if hash&.any?
          rescue StandardError => _e
            # ignore
          end
        end
      end

      # Run on_configuration hooks after config is loaded
      RecordingStudioPages.configuration.hooks.run(:on_configuration, RecordingStudioPages.configuration)
    end

    # Run after_initialize hooks
    initializer "recording_studio_pages.after_initialize", after: "recording_studio_pages.load_config" do |_app|
      RecordingStudioPages.configuration.hooks.run(:after_initialize, self)
    end

    # Apply model extensions when models are loaded
    initializer "recording_studio_pages.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioPages::Engine.apply_model_extensions(model)
        end
      end
    end

    # Apply controller extensions
    initializer "recording_studio_pages.apply_controller_extensions" do
      config.to_prepare do
        next unless defined?(ActionController::Base)

        ActionController::Base.descendants.each do |controller|
          RecordingStudioPages::Engine.apply_controller_extensions(controller)
        end
      end
    end
  end
end
