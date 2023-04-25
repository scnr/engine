require 'scnr/engine/api_runner'

# Provides access to the state of the engine.
State {

    on :change do |state|
        puts "State\t\t- #{state.status.capitalize}"
    end

}

# Provides access to data.
Data {

    Issues {

        on :new do |issue|
            puts "Issue\t\t- #{issue.name} from `#{issue.referring_page.dom.url}`" <<
              " in `#{issue.vector.type}`."
        end

    }

}

# Provides access to message logging.
Logging {

    # Forwards error messages.
    on :error do |error|
        $stderr.puts "Error\t\t- #{error}"
    end

}

# Provides access to DOM operation points.
Dom {

    # Allow some time for the modal animation to complete in order for
    # the login form to appear.
    on :event do |_, locator, event, *|
        next if locator.attributes['href'] != '#myModal' || event != :click
        sleep 1
    end

}

# Provides access to checks.
Checks {

    # Will be called every time a check is run against a page.
    on :run do |check|
        puts "Checking\t- #{check.shortname}"
    end

    # The `as` block will run from the context of SCNR::Engine::Check::Base#run;
    # it basically creates a new check component on the fly.
    #
    # Does something really simple, logs an issue for each 404 page.
    as :not_found,
       name: 'Page not found',
       issue: {
         name:     'Page not found',
         severity: SCNR::Engine::Issue::Severity::INFORMATIONAL
       } do
        response = page.response
        next if response.code != 404

        log(
          proof:  response.status_line,
          vector: SCNR::Engine::Element::Server.new( response.url ),
        )
    end

}

# Provides access to plugins.
Plugins {

    # Called when a plugin gets instantiated.
    on :initialize do |plugin|
        puts "Initialized\t- #{plugin.shortname}"
    end

    # Called when a plugin's #prepare method is run.
    on :prepare do |plugin|
        puts "Preparing\t- #{plugin.shortname}"
    end

    # Called when a plugin's #run method is run.
    on :run do |plugin|
        puts "Running\t\t- #{plugin.shortname}"
    end

    # Called when a plugin's #clean_up method is run.
    on :clean_up do |plugin|
        puts "Cleaning-up\t- #{plugin.shortname}"
    end

    # Called after a plugin's #clean_up method has been ran.
    on :done do |plugin|
        puts "Done\t\t- #{plugin.shortname}"
    end

    # This will run from the context of SCNR::Engine::Plugin::Base; it
    # basically creates a new plugin component on the fly.
    as :my_plugin do
        puts "#{shortname}\t- Running..."
        wait_while_framework_running
        puts "#{shortname}\t- Done!"
    end

}

# Everything scan related.
Scan {

    Options {

        set url:    'http://testhtml5.vulnweb.com',
            audit:  {
              elements: [:links, :forms, :cookies, :ui_forms, :ui_inputs]
            },
            checks: ['*']

    }

    # Configure user session settings.
    Session {

        # Configure a login sequence.
        to :login do |browser|
            print "Session\t\t- Logging in..."

            watir = browser.watir

            # Selenium also available.
            # selenium = browser.selenium

            watir.goto SCNR::Engine::Options.url

            watir.link( href: '#myModal' ).click

            form = watir.form( id: 'loginForm' )
            form.text_field( name: 'username' ).set 'admin'
            form.text_field( name: 'password' ).set 'admin'
            form.submit

            if browser.response.body =~ /<b>admin/
                puts 'done!'
            else
                puts 'failed!'
            end
        end

        # Configure a session check.
        to :check do |async|
            print "Session\t\t- Checking..."

            http_client = SCNR::Engine::HTTP::Client
            check       = proc { |r| r.body.optimized_include? '<b>admin' }

            # If an async block is passed, then the framework would rather
            # schedule it to run asynchronously.
            if async
                http_client.get SCNR::Engine::Options.url do |response|
                    success = check.call( response )

                    puts "logged #{success ? 'in' : 'out'}!"

                    async.call success
                end
            else
                response = http_client.get( SCNR::Engine::Options.url, mode: :sync )
                success = check.call( response )

                puts "logged #{success ? 'in' : 'out'}!"

                success
            end
        end

    }

    # Configure the scope of the scan.
    Scope {

        # Don't visit resources that will end the session.
        reject :url do |url|
            url.path.optimized_include?( 'login' ) ||
              url.path.optimized_include?( 'logout' )
        end

    }

    # Before each page audit but after being prepared for checking.
    on :page do |page|
        puts "Scanning\t- [#{page.response.code}] #{page.dom.url}"
    end

    # Run the scan, wait for it to finish and get the Report and some
    # runtime statistics.
    run! do |report, statistics|
        puts
        puts '=' * 80
        puts

        puts "[#{report.sitemap.size}] Sitemap:"
        puts
        report.sitemap.sort_by { |url, _| url }.each do |url, code|
            puts "\t[#{code}] #{url}"
        end

        puts
        puts '-' * 80
        puts

        puts "[#{report.issues.size}] Issues:"
        puts
        report.issues.each.with_index do |issue, idx|
            s = "\t[#{idx+1}] #{issue.name} in `#{issue.vector.type}`"

            # Not all element types have inputs.
            if issue.vector.respond_to?( :affected_input_name ) &&
                issue.vector.affected_input_name

                s << " input `#{issue.vector.affected_input_name}`"
            end
            puts s << '.'

            puts "\t\tAt `#{issue.page.dom.url}` from `#{issue.referring_page.dom.url}`."

            if issue.proof
                puts "\t\tProof:\n\t\t\t#{issue.proof.gsub( "\n", "\n\t\t\t" )}"
            end

            puts
        end

        puts
        puts '-' * 80
        puts

        puts "Statistics:"
        puts
        puts "\t" << statistics.ai.gsub( "\n", "\n\t" )
    end

}
