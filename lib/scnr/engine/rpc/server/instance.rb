=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'ostruct'

module SCNR::Engine
lib = Options.paths.lib

require lib + 'processes/manager'

require lib + 'rpc/client/instance'

require lib + 'rpc/server/base'
require lib + 'rpc/server/active_options'
require lib + 'rpc/server/output'
require lib + 'rpc/server/framework'

module RPC
class Server

# Represents an Engine instance and serves as a central point of access and control.
#
# # Methods
#
# Provides methods for:
#
# * Retrieving available components:
#   * {#list_checks Checks}
#   * {#list_plugins Plugins}
#   * {#list_reporters Reporters}
# * {#scan Configuring and running a scan}.
# * Retrieving progress information:
#   * {#progress in aggregate form} (which includes a multitude of information).
#   * or simply by:
#       * {#busy? checking whether the scan is still in progress}.
#       * {#status checking the status of the scan}.
# * {#pause Pausing}, {#resume resuming} or {#abort_and_report aborting} the scan.
# * Retrieving the scan report:
#   * {#report as a Hash}.
#   * {#report_as in one of the supported formats} (as made available by the
#     {Reporters Reporter} components).
# * {#shutdown Shutting down}.
#
# @example A minimalistic example -- assumes Engine is installed and available.
#    require 'scnr/engine'
#    require 'scnr/engine/rpc/client'
#
#    instance = SCNR::Engine::RPC::Client::Instance.new( 'localhost:1111', 's3cr3t' )
#
#    instance.scan url: 'http://testfire.net',
#                          audit:  {
#                              elements: [:links, :forms]
#                          },
#                          # load all XSS checks
#                          checks: 'xss*'
#
#    print 'Running.'
#    while instance.busy?
#        print '.'
#        sleep 1
#    end
#
#    # Grab the report
#    report = instance.report
#
#    # Kill the instance and its process, no zombies please...
#    instance.shutdown
#
#    puts
#    puts
#    puts 'Logged issues:'
#    report['issues'].each do |issue|
#       puts "  * #{issue['name']} in '#{issue['vector']['type']}' input '#{issue['vector']['affected_input_name']}' at '#{issue['vector']['action']}'."
#    end
#
# @note Ignore:
#
#   * Inherited methods and attributes -- only public methods of this class are
#       accessible over RPC.
#   * `block` parameters, they are an RPC implementation detail for methods which
#       perform asynchronous operations.
#
# @note Methods which expect `Symbol` type parameters will also accept `String`
#   types as well.
#
#   For example, the following:
#
#       instance.scan url: 'http://testfire.net'
#
#   Is the same as:
#
#       instance.scan 'url' => 'http://testfire.net'
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Instance
    include UI::Output
    include Utilities

    private :error_logfile
    public  :error_logfile

    # Initializes the RPC interface and the framework.
    #
    # @param    [Options]    options
    # @param    [String]    token
    #   Authentication token.
    def initialize( options, token )
        @options = options
        @token   = token

        @framework      = Server::Framework.unsafe
        @active_options = Server::ActiveOptions.new

        @server = Base.new( @options.rpc.to_server_options, token )
        @server.logger.level = @options.datastore.log_level if @options.datastore.log_level

        @options.datastore.token = token

        if @options.output.reroute_to_logfile
            reroute_to_file "#{@options.paths.logs}/Instance - #{Process.pid}" <<
                                "-#{@options.rpc.server_port}.log"
        else
            reroute_to_file false
        end

        set_error_logfile "#{@options.paths.logs}/Instance - #{Process.pid}" <<
                              "-#{@options.rpc.server_port}.error.log"

        set_handlers( @server )

        # trap interrupts and exit cleanly when required
        %w(QUIT INT).each do |signal|
            next if !Signal.list.has_key?( signal )
            trap( signal ){ shutdown if !@options.datastore.do_not_trap }
        end

        Arachni::Reactor.global.run do
            run
        end
    end

    # @return   [String, nil]
    #   Queue URL to which this Instance is attached, `nil` if not attached.
    def queue_url
        @options.queue.url
    end

    # @return   [String, nil]
    #   Dispatcher URL that provided this Instance, `nil` if not provided by a
    #   Dispatcher.
    def dispatcher_url
        @options.dispatcher.url
    end

    # @return   [String, nil]
    #   Path to the {Snapshot snapshot} of the {#suspend suspended} scan,
    #   `nil` if not {#suspended?}.
    #
    # @see #suspend
    # @see #suspended?
    def snapshot_path
        return if !suspended?
        @framework.snapshot_path
    end

    # @note The path to the snapshot can be retrieved via {#snapshot_path}.
    #
    # {Snapshot.dump Writes} a {Snapshot} to disk and aborts the scan.
    #
    # @see #restore
    def suspend
        @framework.suspend false
    end

    # @param (see SCNR::Engine::Framework#restore)
    # @return (see SCNR::Engine::Framework#restore)
    #
    # @see #suspend
    # @see #snapshot_path
    def restore( snapshot )
        @framework.restore snapshot
        @framework.run
        true
    end

    # @return (see SCNR::Engine::Framework#suspended?)
    # @see #suspend
    def suspended?
        @framework.suspended?
    end

    # @return   [true]
    def alive?
        @server.alive?
    end

    # @return   [Bool]
    #   `true` if the scan is initializing or running, `false` otherwise.
    def busy?( &block )
        if @scan_initializing
            block.call( true ) if block_given?
            return true
        end

        @framework.busy?( &block )
    end

    # @param (see SCNR::Engine::RPC::Server::Framework::MultiInstance#errors)
    # @return (see SCNR::Engine::RPC::Server::Framework::MultiInstance#errors)
    def errors( starting_line = 0 )
        @framework.errors( starting_line )
    end

    # @param (see SCNR::Engine::RPC::Server::Framework::MultiInstance#sitemap_entries)
    # @return (see SCNR::Engine::RPC::Server::Framework::MultiInstance#sitemap_entries)
    def sitemap( index = 0 )
        @framework.sitemap_entries( index )
    end

    # @return (see SCNR::Engine::Framework#list_platforms)
    def list_platforms
        @framework.list_platforms
    end

    # @return (see SCNR::Engine::Framework#list_checks)
    def list_checks
        @framework.list_checks
    end

    # @return (see SCNR::Engine::Framework#list_plugins)
    def list_plugins
        @framework.list_plugins
    end

    # @return (see SCNR::Engine::Framework#list_reporters)
    def list_reporters
        @framework.list_reporters
    end

    # @return (see SCNR::Engine::Framework#paused?)
    def paused?
        @framework.paused?
    end

    # Pauses the running scan on a best effort basis.
    def pause( &block )
        if @rpc_pause_request
            block.call( true )
            return
        end

        # Send the pause request but don't block.
        r = @framework.pause( false )
        @rpc_pause_request ||= r

        block.call( true )
    end

    # Resumes a paused scan right away.
    def resume( &block )
        return block.call( false ) if !@rpc_pause_request

        @framework.resume( @rpc_pause_request )

        @rpc_pause_request = nil
        block.call true
    end

    # @note Don't forget to {#shutdown} the instance once you get the report.
    #
    # Cleans up and returns the report.
    #
    # @return  [Hash]
    #
    # @see #report
    def abort_and_report( &block )
        @framework.clean_up { block.call report.to_h }
    end

    # Like {#abort_and_report} but returns a {Serializer.dump} representation
    # of {Report}.
    #
    # @private
    def native_abort_and_report( &block )
        @framework.clean_up { native_report( &block ) }
    end

    # @note Don't forget to {#shutdown} the instance once you get the report.
    #
    # Cleans up and delegates to {#report_as}.
    #
    # @param (see #report_as)
    # @return (see #report_as)
    #
    # @see #abort_and_report
    # @see #report_as
    def abort_and_report_as( name, &block )
        @framework.clean_up { block.call report_as( name ) }
    end

    # @return (see SCNR::Engine::Framework#report)
    # @private
    def native_report( &block )
        @framework.report( &block )
    end

    # @return [Hash]
    #   {Report#to_h}
    def report
        @framework.report.to_h
    end

    # @param    [String]    name
    #   Name of the report component to run, as presented by {#list_reporters}'s
    #   `:shortname` key.
    #
    # @return (see SCNR::Engine::Framework#report_as)
    def report_as( name )
        @framework.report_as( name )
    end

    # @return (see Framework#status)
    def status
        @framework.status
    end

    # # Recommended usage
    #
    #   Please request from the method only the things you are going to actually
    #   use, otherwise you'll just be wasting bandwidth.
    #   In addition, ask to **not** be served data you already have, like issues
    #   or error messages.
    #
    #   To be kept completely up to date on the progress of a scan (i.e. receive
    #   new issues and error messages asap) in an efficient manner, you will need
    #   to keep track of the issues and error messages you already have and
    #   explicitly tell the method to not send the same data back to you on
    #   subsequent calls.
    #
    # ## Retrieving errors (`:errors` option) without duplicate data
    #
    #   This is done by telling the method how many error messages you already
    #   have and you will be served the errors from the error-log that are past
    #   that line.
    #   So, if you were to use a loop to get fresh progress data it would look
    #   like so:
    #
    #     error_cnt = 0
    #     i = 0
    #     while sleep 1
    #         # Test method, triggers an error log...
    #         instance.error_test "BOOM! #{i+=1}"
    #
    #         # Only request errors we don't already have
    #         errors = instance.progress( with: { errors: error_cnt } )[:errors]
    #         error_cnt += errors.size
    #
    #         # You will only see new errors
    #         puts errors.join("\n")
    #     end
    #
    # ## Retrieving issues without duplicate data
    #
    #   In order to be served only new issues you will need to let the method
    #   know which issues you already have. This is done by providing a list
    #   of {Issue#digest digests} for the issues you already know about.
    #
    #     issue_digests = []
    #     while sleep 1
    #         issues = instance.progress(
    #                      with: :issues,
    #                      # Only request issues we don't already have
    #                      without: { issues: issue_digests  }
    #                  )[:issues]
    #
    #         issue_digests |= issues.map { |issue| issue['digest'] }
    #
    #         # You will only see new issues
    #         issues.each do |issue|
    #             puts "  * #{issue['name']} in '#{issue['vector']['type']}' input '#{issue['vector']['affected_input_name']}' at '#{issue['vector']['action']}'."
    #         end
    #     end
    #
    # @param  [Hash]  options
    #   Options about what progress data to retrieve and return.
    # @option options [Array<Symbol, Hash>]  :with
    #   Specify data to include:
    #
    #   * :issues -- Discovered issues as {Engine::Issue#to_h hashes}.
    #   * :errors -- Errors and the line offset to use for {#errors}.
    #     Pass as a hash, like: `{ errors: 10 }`
    # @option options [Array<Symbol, Hash>]  :without
    #   Specify data to exclude:
    #
    #   * :statistics -- Don't include runtime statistics.
    #   * :issues -- Don't include issues with the given {Engine::Issue#digest digests}.
    #     Pass as a hash, like: `{ issues: [...] }`
    #
    # @return [Hash]
    #   * `statistics` -- General runtime statistics (merged when part of Grid)
    #       (enabled by default)
    #   * `status` -- {#status}
    #   * `busy` -- {#busy?}
    #   * `issues` -- Discovered issues as {Engine::Issue#to_h hashes}.
    #       (disabled by default)
    #   * `errors` -- {#errors} (disabled by default)
    #   * `sitemap` -- {#sitemap} (disabled by default)
    def progress( options = {}, &block )
        progress_handler( options.merge( as_hash: true ), &block )
    end

    # Like {#progress} but returns MessagePack representation of native objects
    # instead of simplified hashes.
    #
    # @private
    def native_progress( options = {}, &block )
        progress_handler( options.merge( as_hash: false ), &block )
    end

    # Configures and runs a scan.
    #
    # @note Options marked with an asterisk are required.
    # @note Options which expect patterns will interpret their arguments as
    #   regular expressions regardless of their type.
    #
    # @param  [Hash]  opts
    #   Scan options to be passed to {Options#update} (along with some extra ones
    #   to keep configuration in one place).
    #
    #   _The options presented here are the most commonly used ones, in
    #   actuality, you can use anything supported by {Options#update}._
    # @option opts [String]  *:url
    #   Target URL to audit.
    # @option opts [String] :authorized_by (nil)
    #   The e-mail address of the person who authorized the scan.
    #
    #       john.doe@bigscanners.com
    # @option opts [Hash] :audit
    #   {OptionGroups::Audit Audit} options.
    # @option opts [Hash] :scope
    #   {OptionGroups::Scope Scope} options.
    # @option opts [Hash] :http
    #   {OptionGroups::HTTP HTTP} options.
    # @option opts [Hash] :login
    #   {OptionGroups::Session Session} options.
    # @option opts [String,Array<String>] :checks ([])
    #   Checks to load, by name.
    #
    #       # To load all checks use the wildcard on its own
    #       '*'
    #
    #       # To load all XSS and SQLi checks:
    #       [ 'xss*', 'sql_injection*' ]
    #
    # @option opts [Hash<Hash>] :plugins ({})
    #   Plugins to load, by name, along with their options.
    #
    #       {
    #           'proxy'      => {}, # empty options
    #           'form_login' => {
    #               'url'         => 'http://demo.testfire.net/bank/login.aspx',
    #               'parameters' => 'uid=jsmith&passw=Demo1234',
    #               'check'       => 'MY ACCOUNT'
    #           },
    #       }
    #
    # @option opts [String, Symbol, Array<String, Symbol>] :platforms ([])
    #   Initialize the fingerprinter with the given platforms.
    #
    #   The fingerprinter cannot identify database servers so specifying the
    #   remote DB backend will greatly enhance performance and reduce bandwidth
    #   consumption.
    # @option opts [Bool] :no_fingerprinting (false)
    #   Disable platform fingerprinting and include all payloads in the audit.
    #
    #   Use this option in addition to the `:platforms` one to restrict the
    #   audit payloads to explicitly specified platforms.
    def scan( opts = {}, &block )
        # If the instance isn't clean bail out now.
        if busy? || @called
            block.call false
            return false
        end

        # Normalize this sucker to have symbols as keys.
        opts = opts.my_symbolize_keys( false )

        if (platforms = opts.delete(:platforms))
            begin
                Platform::Manager.new( [platforms].flatten.compact )
            rescue => e
                fail ArgumentError, e.to_s
            end
        end

        opts[:scope] ||= {}

        # There may be follow-up/retry calls by the client in cases of network
        # errors (after the request has reached us) so we need to keep minimal
        # track of state in order to bail out on subsequent calls.
        @called = @scan_initializing = true

        # Plugins option needs to be a hash...
        if opts[:plugins] && opts[:plugins].is_a?( Array )
            opts[:plugins] = opts[:plugins].inject( {} ) { |h, n| h[n] = {}; h }
        end

        @active_options.set( opts )

        if SCNR::Engine::Options.url.to_s.empty?
            fail ArgumentError, 'Option \'url\' is mandatory.'
        end

        @framework.checks.load opts[:checks] if opts[:checks]
        @framework.plugins.load opts[:plugins] if opts[:plugins]

        block.call @framework.run
        @scan_initializing = false

        true
    end

    # Makes the server go bye-bye...Lights out!
    def shutdown( &block )
        if @shutdown
            block.call if block_given?
            return
        end
        @shutdown = true

        print_status 'Shutting down...'

        # We're shutting down services so we need to use a concurrent way but
        # without going through the Reactor.
        Thread.new do
            t = []

            if browser_cluster
                # We can't block until the browser cluster shuts down cleanly
                # (i.e. wait for any running jobs) but we don't need to anyways.
                t << Thread.new { browser_cluster.shutdown false }
            end

            @server.shutdown

            block.call true if block_given?
        end

        true
    end

    # @private
    def error_test( str, &block )
        @framework.error_test( str, &block )
    end

    # @private
    def consumed_pids
        [Process.pid]
    end

    # For testing.
    # @private
    def cookies
        SCNR::Engine::HTTP::Client.cookies.map(&:to_rpc_data)
    end

    # For testing.
    # @private
    def clear_cookies
        SCNR::Engine::Options.reset
        SCNR::Engine::HTTP::Client.cookie_jar.clear
        true
    end

    private

    def browser_cluster
        @framework.instance_eval { @browser_cluster }
    end

    def progress_handler( options = {}, &block )
        with    = parse_progress_opts( options, :with )
        without = parse_progress_opts( options, :without )

        options = {
            as_hash:    options[:as_hash],
            issues:     with.include?( :issues ),
            statistics: !without.include?( :statistics )
        }

        if with[:errors]
            options[:errors] = with[:errors]
        end

        if with[:sitemap]
            options[:sitemap] = with[:sitemap]
        end

        @framework.progress( options ) do |data|
            data[:busy] = busy?

            if data[:issues]
                if without[:issues].is_a? Array
                    data[:issues].reject! do |i|
                        without[:issues].include?( i[:digest] || i['digest'] )
                    end
                end
            end

            block.call( data )
        end
    end

    def parse_progress_opts( options, key )
        parsed = {}
        [options.delete( key ) || options.delete( key.to_s )].compact.each do |w|
            case w
                when Array
                    w.compact.flatten.each do |q|
                        case q
                            when String, Symbol
                                parsed[q.to_sym] = nil

                            when Hash
                                parsed.merge!( q.my_symbolize_keys )
                        end
                    end

                when String, Symbol
                    parsed[w.to_sym] = nil

                when Hash
                    parsed.merge!( w.my_symbolize_keys )
            end
        end

        parsed
    end

    # Starts  RPC service.
    def run
        Arachni::Reactor.global.on_error do |_, e|
            print_error "Reactor: #{e}"

            e.backtrace.each do |l|
                print_error "Reactor: #{l}"
            end
        end

        print_status 'Starting the server...'
        @server.start
    end

    # Outputs the Engine banner.
    #
    # Displays version number, author details etc.
    def banner
        puts BANNER
        puts
        puts
    end

    # @param    [Base]  server
    #   Prepares all the RPC handlers for the given `server`.
    def set_handlers( server )
        server.add_async_check do |method|
            # methods that expect a block are async
            method.parameters.flatten.include? :block
        end

        server.add_handler( 'instance', self )
        server.add_handler( 'options',  @active_options )
    end

end

end
end
end
