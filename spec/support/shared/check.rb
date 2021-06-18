shared_examples_for 'check' do
    include_examples 'component'

    module Format
        include SCNR::Engine::Element::Capabilities::Mutable::Format
    end

    module Element
        include SCNR::Engine::Element
    end

    module Severity
        include SCNR::Engine::Severity
    end

    before( :all ) do
        @issues = []
    end

    after(:each ) do
        options.reset
        framework.reset
    end

    before( :each ) do
        options.reset
        options.url                        = url
        options.audit.parameter_names      = true
        options.audit.with_raw_payloads    = true
        options.audit.with_extra_parameter = true
        options.device.user_agent          = 'scnr_engine_user'
        options.browser_pool.update( options.browser_pool.defaults )

        framework.reset

        framework.checks.lib = options.paths.checks
        framework.checks.load name

        # Do not deduplicate, the check tests need to see everything.
        current_check.instance_eval do
            define_method( :duplicate_check? ) { |_| false }
        end

        SCNR::Engine::Data.issues.do_not_store
        SCNR::Engine::Data.issues.on_new_pre_deduplication do |issue|
            @issues << issue

            # Leave this here, helps us save every kind of issue in order to test
            # the reporters.
            if $spec_issues
                $spec_issues << issue
            end
        end

        SCNR::Engine::Element::Capabilities::Analyzable::Timeout.do_not_deduplicate

        # Force the sink trace to run prior to the checks.
        Element::Capabilities::WithSinks::Sinks.add_to_max_cost 9999
        Element::DOM::Capabilities::WithSinks::Sinks.add_to_max_cost 9999
    end

    after( :each ) do
        @issues.clear
    end

    describe '.info' do
        it 'holds the right cost' do
            expect(current_check.cost).to eq self.class.cost
        end

        it 'holds the right sink info' do
            expect(current_check.sink).to eq self.class.sink
        end

        it 'holds the right platforms' do
            expect(current_check.platforms.sort).to eq self.class.platforms.sort
        end

        it 'holds the right elements' do
            expect(current_check.info[:elements].map(&:to_s).sort).to eq(self.class.elements.map(&:to_s).sort)
        end

        context 'when it has references' do
            it 'they are still available' do
                if !(current_check.info[:issue] && current_check.info[:issue][:references])
                    next
                end

                hydra = Typhoeus::Hydra.new

                current_check.info[:issue][:references].each do |title, url|
                    r = Typhoeus::Request.new(
                        url,
                        followlocation: true,
                        timeout_ms:     5000,
                        headers:        {
                            'User-Agent' => 'Mozilla/5.0 (Windows NT x.y; rv:10.0) Gecko/20100101 Firefox/10.0'
                        }
                    )
                    r.on_complete do |response|
                        expect(response.code).to eq(200), "#{response.code} -- #{title} => #{url}"
                    end
                    hydra.queue r
                end

                hydra.run
            end
        end
    end

    def self.easy_test( run_checks = true, &block )
        if self.platforms.any?
            context 'when the platform is' do
                platforms.each do |platform|
                    test_platform( platform, run_checks, &block )
                end
            end
        else
            elements.each do |element|
                test_element( element, nil, run_checks, &block )
            end
        end
    end

    def self.test_platform( platform, run_checks, &block )
        context platform do
            elements.each do |element|
                test_element( element, platform, run_checks, &block )
            end
        end
    end

    def self.test_element( element, platform, run_checks, &block )
        it "logs vulnerable #{element.type} elements" do
            run_test element, platform, run_checks, &block
        end
    end

    def run_test( element, platform, run_checks, &block )
        if !issue_count && !issue_count_per_platform &&
            !issue_count_per_element && !issue_count_per_element_per_platform
            raise 'No issue count provided via a suitable method.'
        end

        options.url = url + platform.to_s
        options.scope.include_path_patterns = options.url

        audit element, run_checks

        if issue_count
            expect(issues.size).to eq issue_count
        end

        if issue_count_per_platform
            expect(issues.size).to eq issue_count_per_platform[platform]
        end

        if issue_count_per_element
            expect(issues.size).to eq issue_count_per_element[element]
        end

        if issue_count_per_element_per_platform
            expect(issues.size).to eq issue_count_per_element_per_platform[platform][element]
        end

        instance_eval &block if block_given?
    end

    def issues
        @issues
    end

    def issue_count
    end

    def issue_count_per_platform
    end

    def issue_count_per_element
    end

    def issue_count_per_element_per_platform
    end

    def self.platforms
        []
    end

    def self.cost
        nil
    end

    def self.sink
        nil
    end

    def self.elements
    end

    def audit( element_type, logs_issues = true )
        if !element_type.is_a?( Symbol )
            element_type = element_type.type
        end

        self.class.elements.map(&:type).each do |type|
            options.audit.skip_elements type rescue NoMethodError
        end

        if element_type.to_s.start_with? 'link_template'
            options.audit.link_templates = [
                /\/input\/(?<input>.+)\//,
                /input\|(?<input>.+)/
            ]
        else
            options.audit.elements element_type rescue NoMethodError
        end

        run

        e = element_type.to_s
        e << 's' if element_type.to_s[-1] != 's'

        e = element_type.to_s
        e = e[0...-1] if element_type.to_s[-1] == 's'

        if logs_issues && issues.any?
            # make sure we ONLY got results for the requested element type
            expect(issues.map { |i| i.vector.class.type }.uniq).to eq [e.to_sym]

            if current_check.info[:issue]
                expect(issues.map { |i| i.severity }.uniq).to eq [current_check.info[:issue][:severity]]
            end
        end
    end

    def current_check
        framework.checks.values.first
    end

    def url
        @url ||= (
                begin
                    web_server_url_for( "#{name}_check" )
                rescue
                    begin
                        web_server_url_for( name )
                    rescue
                        web_server_url_for( "#{name}_https" )
                    end
                end
        )  + '/'
    end

end
