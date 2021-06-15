child :input, :Input do
    define :values
    def_values do |&block|
        SCNR::Engine::Options.input.filler( &block )
    end
end
