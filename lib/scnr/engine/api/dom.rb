child :dom, :DOM do
    define :before

    def_before :load do |&block|
        SCNR::Engine::Browser::Parts::Navigation.before_load( &block )
    end

    def_before :event do |&block|
        SCNR::Engine::Browser::Parts::Events.before_event( &block )
    end

    define :on

    def_on :event do |&block|
        SCNR::Engine::Browser::Parts::Events.on_event( &block )
    end

    define :after

    def_after :load do |&block|
        SCNR::Engine::Browser::Parts::Navigation.after_load( &block )
    end

    def_after :event do |&block|
        SCNR::Engine::Browser::Parts::Events.after_event( &block )
    end
end
