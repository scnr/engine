=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine

lib = Options.paths.lib

require lib + 'processes/manager'
require lib + 'processes/instances'

require lib + 'rpc/client/instance'
require lib + 'rpc/client/dispatcher'

require lib + 'rpc/server/base'
require lib + 'rpc/server/output'

module RPC
class Server

# RPC queue service which:
#
# * Maintains a priority queue of scan jobs.
# * {#push Accepts jobs.}
# * Runs them once a slot is available -- determined by
#   {System#utilization system utilization}.
# * Monitors {#running} scans, retrieves and
#   {OptionGroups::Paths#reports stores} their {Report reports} and shuts down
#   their {Instance} to free its slot.
# * Makes available information on {#completed} and {#failed} scans.
#
# In addition to the purely queue functionality, it also allows for running
# scans to be:
#
# * {#detach Detached} from the queue monitor and transfer the management
#   responsibility to the client.
# * {#attach Attached} to the queue monitor and transfer the management
#   responsibility to the queue.
#
# If a {Dispatcher} has been provided, {Instance instances} will be
# {Dispatcher#dispatch provided} by it.
# If no {Dispatcher} has been given, {Instance instances} will be spawned on the
# Queue machine.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Queue
    include UI::Output
    include Utilities

    def initialize
        @options = Options.instance

        @options.snapshot.path ||= @options.paths.snapshots
        @options.report.path   ||= @options.paths.reports

        @server = Base.new( @options.rpc.to_server_options )
        @server.logger.level = @options.datastore.log_level if @options.datastore.log_level

        Options.queue.url = @url = @server.url

        prep_logging

        @queue          = {}
        @id_to_priority = {}
        @by_priority    = {}

        @running   = {}
        @completed = {}
        @failed    = {}

        set_handlers( @server )
        trap_interrupts { Thread.new { shutdown } }

        monitor_scans
        consume_queue

        run
    end

    # @return   [Bool]
    def empty?
        self.size == 0
    end

    # @return   [Bool]
    def any?
        !empty?
    end

    # @return   [Integer]
    def size
        @queue.size
    end

    # @return   [Hash<Integer,Array>]
    #   Queued scans grouped and sorted by priority.
    def list
        @by_priority
    end

    # @return   [Hash]
    #   {RPC::Client::Instance RPC connection information} on running scans.
    def running
        @running.inject( {} ) do |h, (id, client)|
            h.merge! id => { url: client.url, token: client.token, pid: client.pid }
            h
        end
    end

    # @return   [Hash]
    #   Completed scans and their report location.
    def completed
        @completed
    end

    # @return   [Hash]
    #   Failed scans and the associated error.
    def failed
        @failed
    end

    # @note Only returns info for queued scans, once a scan has passed through
    #   the {#running} stage it's no longer part of the queue.
    #
    # @param    [String]    id
    #   ID for a queued scan.
    #
    # @return   [Hash, nil]
    #   * Scan options and priority.
    #   * `nil` if a scan with the given ID could not be found.
    def get( id )
        return if !@queue.include? id

        {
            options:  @queue[id],
            priority: @id_to_priority[id]
        }
    end

    # @param    [Hash]  options
    #   {Instance#scan Scan options} with an extra `priority` option which
    #   defaults to `0` (higher is more urgent).
    #
    # @return   [String]
    #   Scan ID used to reference the scan from then on.
    def push( options )
        priority = options.delete('priority') || 0

        validate_options options

        id = Utilities.generate_token

        @queue[id]          = options
        @id_to_priority[id] = priority

        (@by_priority[priority] ||= []) << id
        @by_priority = Hash[@by_priority.sort_by { |k, _| -k }]

        id
    end

    # @note Only affects queued scans, once a scan has passed through
    #   the {#running} stage it's no longer part of the queue.
    #
    # @param    [String]    id
    #   Scan ID to remove from the queue.
    def remove( id )
        return false if !@queue.include? id

        @queue.delete( id )
        @by_priority[@id_to_priority.delete( id )].delete( id )

        true
    end

    # @param    [String]    id
    #   Running scan to detach from the queue monitor.
    #
    #   Once a scan is detached it becomes someone else's responsibility to
    #   monitor, manage and shutdown to free its slot.
    #
    # @return   [Hash, nil]
    #   * {RPC::Client::Instance RPC connection information} for the scan.
    #   * `nil` if no running scan with that ID is found.
    def detach( id, &block )
        client = @running.delete( id )
        return block.call if !client

        client.options.set( queue: { url: nil } ) do
            block.call( url: client.url, token: client.token, pid: client.pid )
        end
    end

    # Attaches a running scan to the queue monitor.
    #
    # @param    [String]    url
    #   Instance URL for a running scan.
    # @param    [String]    token
    #   Authentication token for the Instance.
    #
    # @return   [String, false, nil]
    #   * Scan ID for further queue reference.
    #   * `false` if the Instance is already attached to a Queue.
    #   * `nil` if the Instance could not be reached.
    def attach( url, token, &block )
        client = connect_to_instance( url, token )
        client.alive? do |bool|
            if bool.rpc_exception?
                block.call
                next
            end

            client.queue_url do |queue_url|
                if queue_url
                    block.call false
                    next
                end

                client.options.set( queue: { url: @options.queue.url } ) do
                    @running[token] = client
                    block.call token
                end
            end
        end
    end

    # @note Only affects queued scans, once a scan has passed through the
    #   {#running} stage it's no longer part of the queue.
    #
    # Empties the queue.
    def clear
        @queue.clear
        @by_priority.clear
        @id_to_priority.clear

        nil
    end

    # Shuts down the service.
    def shutdown
        print_status 'Shutting down...'
        reactor.delay 2 do
            reactor.stop
        end
    end

    # @param    [Integer]   starting_line
    #   Sets the starting line for the range of errors to return.
    #
    # @return   [Array<String>]
    def errors( starting_line = 0 )
        return [] if self.error_buffer.empty?

        error_strings = self.error_buffer

        if starting_line != 0
            error_strings = error_strings[starting_line..-1]
        end

        error_strings
    end

    # @return   [TrueClass]
    def alive?
        @server.alive?
    end

    protected

    def pop
        return if @queue.empty?

        top_priority, q = @by_priority.first

        id = q.pop
        r = [id, @queue.delete( id )]

        @by_priority.delete( top_priority ) if q.empty?

        r
    end

    private

    def validate_options( options )
        SCNR::Engine::Options.allocate.reset.update( options )
    end

    def consume_queue
        spawning = false
        reactor.at_interval( Options.queue.ping_interval ) do
            next if self.empty? || spawning

            spawning = true
            spawn_instance do |client|
                if client == :error
                    spawning = false
                    next
                end

                if !client
                    print_debug 'Could not get Instance, all systems are at max utilization.'
                    spawning = false
                    next
                end

                id, options = self.pop

                print_status "[#{id}] Got Instance: #{client.url}/#{client.token}"

                client.scan( options ) do
                    spawning = false

                    print_status "[#{id}] Scan started."
                    @running[id] = client
                end
            end
        end
    end

    def monitor_scans
        checking = false
        reactor.at_interval( Options.queue.ping_interval ) do
            next if checking
            print_debug 'Checking running scans.'
            checking = true

            each  = proc { |(id, c), i| check_scan( id, c ) { i.next } }
            after = proc { checking = false }
            reactor.create_iterator( @running ).each( each, after )
        end
    end

    def check_scan( id, client, &block )
        print_debug "[#{id}] Checking status."

        client.busy? do |busy|
            if busy.rpc_exception?
                handle_rpc_error( id, busy )
                block.call
            elsif busy
                print_debug "[#{id}] Busy."
                block.call
            else
                get_report_and_shutdown( id, client, &block )
            end
        end
    end

    def handle_rpc_error( id, error )
        print_error "[#{id}] Failed: [#{error.class}] #{error.to_s}"

        @failed[id] = {
            error:       error.class.to_s,
            description: error.to_s
        }
        c = @running.delete( id )
        c.close if c
    end

    def get_report_and_shutdown( id, client, &block )
        print_status "[#{id}] Grabbing report."

        client.native_report do |report|
            if report.rpc_exception?
                handle_rpc_error( id, report )
                block.call
                next
            end

            path = report.save( "#{Options.report.path}/#{id}.ser" )

            print_status "[#{id}] Report saved at: #{path}"

            client.shutdown do
                print_status "[#{id}] Completed."

                @running.delete( id ).close
                @completed[id] = path

                block.call
            end
        end
    end

    # Starts the dispatcher's server
    def run
        reactor.on_error do |_, e|
            print_error "Reactor: #{e}"

            e.backtrace.each do |l|
                print_error "Reactor: #{l}"
            end
        end

        print_status 'Ready'
        @server.start
    rescue => e
        print_exception e

        $stderr.puts "Could not start server, for details see: #{@logfile}"
        exit 1
    end

    def reactor
        Arachni::Reactor.global
    end

    def trap_interrupts( &block )
        %w(QUIT INT).each do |signal|
            trap( signal, &block || Proc.new{ } ) if Signal.list.has_key?( signal )
        end
    end

    def prep_logging
        # reroute all output to a logfile
        @logfile ||= reroute_to_file(
            @options.paths.logs + "/Queue - #{Process.pid}-#{@options.rpc.server_port}.log"
        )
    end

    def dispatcher
        return if !Options.dispatcher.url
        @dispatcher ||= RPC::Client::Dispatcher.new( Options.dispatcher.url )
    end

    def spawn_instance( &block )
        if dispatcher
            args = [
                'queue',
                {
                    owner: {
                        url: @url
                    }
                }
            ]

            dispatcher.dispatch *args do |info|
                if info.rpc_exception?
                    print_error "Failed to contact Dispatcher at: #{dispatcher.url}"
                    print_error "[#{info.class}] #{info.to_s}"
                    block.call :error
                    next
                end

                if info
                    client = connect_to_instance( info['url'], info['token'] )
                    client.options.set( queue: { url: @options.queue.url } ) do
                        block.call( client )
                    end

                else
                    block.call
                end
            end
        else
            return block.call if System.max_utilization?

            Processes::Instances.spawn(
                port_range: Options.queue.instance_port_range,
                &block
            )
        end
    end

    def connect_to_instance( url, token )
        RPC::Client::Instance.new( url, token )
    end

    # @param    [Base]  server
    #   Prepares all the RPC handlers for the given `server`.
    def set_handlers( server )
        server.add_async_check do |method|
            # methods that expect a block are async
            method.parameters.flatten.include? :block
        end

        server.add_handler( 'queue', self )
    end

end

end
end
end
