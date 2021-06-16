child :data, :Data do

    child :sitemap, :Sitemap do
        define :on

        def_on :new do |&block|
            SCNR::Engine::Framework.unsafe.data.on_sitemap_entry( &block )
        end
    end

    child :urls, :URLs do
        define :on

        def_on :new do |&block|
            SCNR::Engine::Framework.unsafe.data.on_url( &block )
        end
    end

    child :pages, :Pages do
        define :on

        def_on :new do |&block|
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
