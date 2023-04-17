child :plugins, :Plugins do
    def_on :initialize do |&block|
        SCNR::Engine::UnsafeFramework.plugins.on_initialize &block
    end

    def_on :prepare do |&block|
        SCNR::Engine::UnsafeFramework.plugins.on_prepare &block
    end

    def_on :run do |&block|
        SCNR::Engine::UnsafeFramework.plugins.on_run &block
    end

    def_on :clean_up do |&block|
        SCNR::Engine::UnsafeFramework.plugins.on_clean_up &block
    end

    def_on :done do |&block|
        SCNR::Engine::UnsafeFramework.plugins.on_done &block
    end

    def_as do |shortname, info = {}, &block|
        shortname = shortname.to_s

        plugin = Class.new( SCNR::Engine::Plugin::Base )
        plugin.shortname = shortname
        plugin.define_method :run, &block
        plugin.define_singleton_method :info, &proc { info }

        SCNR::Engine::UnsafeFramework.plugins[shortname] = plugin
    end
end
