child :fingerprinters, :Fingerprinters do
    UnsafeFramework = SCNR::Engine::Framework.unsafe

    def_as do |shortname, &block|
        shortname = shortname.to_s

        fingerprinter = Class.new( SCNR::Engine::Platform::Fingerprinter )
        fingerprinter.define_method :run, &block
        fingerprinter.define_method :shortname, &proc{ shortname }

        SCNR::Engine::Platform::Manager.fingerprinters[shortname] =
          fingerprinter
    end
end
