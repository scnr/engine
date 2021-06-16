child :options, :Options do
    define :set

    describe 'Sets Engine options.'
    def_set do |*args|
        SCNR::Engine::Options.set *args
        SCNR::Engine::Options.validate
    end

end
