child :scan, :Scan do
    import_many "#{SCNR::Engine::Options.paths.lib}/api/scan/*"

    UnsafeFramework = SCNR::Engine::Framework.unsafe

    Kernel.at_exit do
        UnsafeFramework.clean_up
        UnsafeFramework.reset
    end

    define :run!
    def_run! do |&block|
        SCNR::Engine::Framework.safe do |framework|
            framework.checks.load SCNR::Engine::Options.checks

            framework.plugins.load_defaults
            framework.plugins.load SCNR::Engine::Options.plugins.keys

            framework.run
            block.call framework.report, framework.statistics
        end
    end

    define :run
    def_run do
        UnsafeFramework.checks.load SCNR::Engine::Options.checks

        UnsafeFramework.plugins.load_defaults
        UnsafeFramework.plugins.load SCNR::Engine::Options.plugins.keys

        UnsafeFramework.run

        [UnsafeFramework.report, UnsafeFramework.statistics]
    end

    define :progress
    def_progress do
        {
          running:          running?,
          status:           status,
          status_messages:  status_messages,
          sitemap:          sitemap,
          issues:           issues,
          statistics:       statistics
        }
    end

    define :sitemap
    def_sitemap do |index = 0|
        return {} if UnsafeFramework.sitemap.size <= index + 1
        Hash[UnsafeFramework.sitemap.to_a[index..-1] || {}]
    end

    define :status
    def_status do
        s = UnsafeFramework.state.status
        s.nil? ? :nil : s
    end

    define :errors
    def_errors do |index = 0|
        []
    end

    define :issues
    def_issues do |without = []|
        without = Set.new( without )
        SCNR::Engine::Data.issues.sort.
          reject { |i| without.include? i.digest }
    end

    %w(
        status_messages
        statistics
        running?
        scanning?
        pause! pausing? paused?
        resume!
        abort!
        suspend! suspended?
    ).each do |m|
        define m
        send( "def_#{m}", &proc { UnsafeFramework.send( m ) } )
    end

    define :restore!
    def_restore! do |snapshot|
        UnsafeFramework.restore! snapshot
        nil
    end

end
