child :scan, :Scan do
    import_many "#{SCNR::Engine::Options.paths.lib}/api/scan/*"

    UnsafeFramework = SCNR::Engine::Framework.unsafe

    Kernel.at_exit do
        UnsafeFramework.clean_up
        UnsafeFramework.reset
    end

    def_run! do |&block|
        SCNR::Engine::Framework.safe do |framework|
            framework.checks.load SCNR::Engine::Options.checks

            framework.plugins.load_defaults
            framework.plugins.load SCNR::Engine::Options.plugins.keys

            framework.run
            block.call framework.report, framework.statistics
        end
    end

    def_run do
        UnsafeFramework.checks.load SCNR::Engine::Options.checks

        UnsafeFramework.plugins.load_defaults
        UnsafeFramework.plugins.load SCNR::Engine::Options.plugins.keys

        UnsafeFramework.run

        [UnsafeFramework.report, UnsafeFramework.statistics]
    end

    def_progress do
        {
          running:          running?,
          status:           status,
          status_messages:  status_messages,
          errors:           errors,
          sitemap:          sitemap,
          issues:           issues,
          statistics:       statistics
        }
    end

    def_session_progress do |session_id = nil|
        @session ||= {}
        @session[session_id] ||= {
          seen_issues:    Set.new,
          sitemap_offset: 0,
          error_offset:   0
        }

        progress = {
          running:          running?,
          status:           status,
          status_messages:  status_messages,
          errors:           errors( @session[session_id][:error_offset] ),
          sitemap:          sitemap( @session[session_id][:sitemap_offset] ),
          issues:           issues( @session[session_id][:seen_issues] ),
          statistics:       statistics
        }

        @session[session_id][:error_offset]   += progress[:errors].size
        @session[session_id][:sitemap_offset] += progress[:sitemap].size
        @session[session_id][:seen_issues]    |= progress[:issues].map(&:digest)

        progress
    end

    def_sitemap do |index = 0|
        return {} if UnsafeFramework.sitemap.size <= index + 1
        Hash[UnsafeFramework.sitemap.to_a[index..-1] || {}]
    end

    def_status do
        s = UnsafeFramework.state.status
        s.nil? ? :nil : s
    end

    def_errors do |index = 0|
        []
    end

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
        suspend! suspending? suspended?
    ).each do |m|
        send( "def_#{m}", &proc { UnsafeFramework.send( m ) } )
    end

    def_restore! do |snapshot|
        UnsafeFramework.restore! snapshot
        nil
    end

    def_generate_report do
        UnsafeFramework.report
    end

end
