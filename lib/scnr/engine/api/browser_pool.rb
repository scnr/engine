child :browserpool, :BrowserPool do

    def_on :job do |&block|
        SCNR::Engine::BrowserPool.on_queue( &block )
    end

    def_on :job_done do |&block|
        SCNR::Engine::BrowserPool.on_job_done( &block )
    end

    def_on :result do |&block|
        SCNR::Engine::BrowserPool.on_result( &block )
    end

end
