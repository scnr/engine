child :input, :Input do
    def_values do |&block|
        SCNR::Engine::Options.input.filler( &block )
    end
end
