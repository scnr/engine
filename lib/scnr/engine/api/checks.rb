child :checks, :Checks do
    def_on :run do |&block|
        SCNR::Engine::UnsafeFramework.checks.on_run &block
    end

    def_as do |shortname, info = {}, &block|
        shortname = shortname.to_s

        check = Class.new( SCNR::Engine::Check::Base )
        check.shortname = shortname
        check.define_method :run, &block
        check.define_singleton_method :info, &proc { info }

        SCNR::Engine::UnsafeFramework.checks[shortname] = check
    end
end
