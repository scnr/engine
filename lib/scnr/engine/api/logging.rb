child :logging, :Logging do
    def_on :error do |&block|
        SCNR::Engine::UI::Output.on_error( &block )
    end

    def_on :exception do |&block|
        SCNR::Engine::Error.on_new( &block )
    end
end
