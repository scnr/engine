child :http, :HTTP do
    define :on

    def_on :request do |&block|
        SCNR::Engine::HTTP::Client.on_queue( &block )
    end

    def_on :response do |&block|
        SCNR::Engine::HTTP::Client.on_complete( &block )
    end

    def_on :cookies do |&block|
        SCNR::Engine::HTTP::Client.on_new_cookies( &block )
    end

    define :after

    def_after :run do |&block|
        SCNR::Engine::HTTP::Client.after_each_run( &block )
    end
end
