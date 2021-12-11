child :checks, :Checks do
    UnsafeFramework = SCNR::Engine::Framework.unsafe

    def_on :run do |&block|
        UnsafeFramework.checks.on_run &block
    end

    def_as do |shortname, info = {}, &block|
        shortname = shortname.to_s

        check = Class.new( SCNR::Engine::Check::Base )
        check.shortname = shortname
        check.define_method :run, &block
        check.define_singleton_method :info, &proc { info }

        UnsafeFramework.checks[shortname] = check
    end
end
