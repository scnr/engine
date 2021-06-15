child :data, :Data do
    child :framework, :Framework do
        define :on

        def_on :sitemap_entry do |&block|
            SCNR::Engine::Framework.unsafe.data.on_sitemap_entry( &block )
        end

        def_on :url do |&block|
            SCNR::Engine::Framework.unsafe.data.on_url( &block )
        end

        def_on :page do |&block|
            SCNR::Engine::Framework.unsafe.data.on_page( &block )
        end
    end

    child :issues, :Issues do
        define :on

        def_on :new do |&block|
            SCNR::Engine::Data.issues.on_new( &block )
        end

        define :disable
        def_disable :storage do
            SCNR::Engine::Data.issues.do_not_store
        end
    end
end
