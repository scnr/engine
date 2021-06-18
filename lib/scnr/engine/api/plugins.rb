child :plugins, :Plugins do
    UnsafeFramework = SCNR::Engine::Framework.unsafe

    def_as do |shortname, info = {}, &block|
        shortname = shortname.to_s

        plugin = Class.new( SCNR::Engine::Plugin::Base )
        plugin.shortname = shortname
        plugin.define_method :run, &block
        plugin.define_singleton_method :info, &proc { info }

        UnsafeFramework.plugins[shortname] = plugin
    end
end
