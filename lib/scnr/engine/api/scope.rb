child :scope, :Scope do
    define :select

    def_select :url do |&block|
        SCNR::Engine::URI::Scope.select( &block )
    end

    def_select :page do |&block|
        SCNR::Engine::Page::Scope.select( &block )
    end

    def_select :element do |&block|
        SCNR::Engine::Element::Capabilities::WithScope::Scope.select( &block )
    end

    def_select :event do |&block|
        SCNR::Engine::Browser::Parts::Events.select( &block )
    end


    define :reject

    def_reject :url do |&block|
        SCNR::Engine::URI::Scope.reject( &block )
    end

    def_reject :page do |&block|
        SCNR::Engine::Page::Scope.reject( &block )
    end

    def_reject :element do |&block|
        SCNR::Engine::Element::Capabilities::WithScope::Scope.reject( &block )
    end

    def_reject :event do |&block|
        SCNR::Engine::Browser::Parts::Events.reject( &block )
    end
end
