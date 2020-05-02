class Auditor < SCNR::Engine::Check::Base
    include SCNR::Engine::Check::Auditor

    attr_accessor :page
    attr_accessor :framework

    self.shortname = 'auditor_test'

    def initialize( page = nil, framework = nil)
        super
        http.update_cookies( page.cookie_jar ) if page
    end

    # Normally this does not accept blocks, but it's much easier to test
    # element capabilities this way, so we translate blocks to class methods.
    def with_browser( *args, &block )
        if args.last.is_a? Method
            final_args = args
        elsif block_given?
            final_args = args
            final_args << proc_to_method( &block )
        else
            fail ArgumentError, 'Missing callback.'
        end

        super( *final_args )
    end

    def self.info
        {
            name: 'Auditor',
            issue:       {
                name:            %q{Test issue},
                description:     %q{Test description},
                tags:            ['some', 'tag'],
                cwe:             '0',
                severity:        Issue::Severity::HIGH,
                remedy_guidance: %q{Watch out!.},
                remedy_code:     ''
            }
        }
    end
end
