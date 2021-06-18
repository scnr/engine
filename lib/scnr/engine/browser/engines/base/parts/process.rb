=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
class Engines

    class Error

        # Raised when the browser could not be started.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class Spawn < Error
        end

        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class MissingExecutable < Error
        end

        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class NotExecutable < Error
        end

    end

class Base
module Parts

module Process

    # How much time to wait for the browser process to start before restarting.
    SPAWN_TIMEOUT = 10

    # @return   [Integer]
    #   PID of the lifeline process managing the browser process.
    attr_reader :lifeline_pid

    # @return   [Integer]
    #   PID of the browser process.
    attr_reader :pid

    def self.included( base )
        base.extend ClassMethods
    end

    module ClassMethods
        def find_executable( bin )
            path = Processes::Manager.find( bin )

            if !path
                raise Error::MissingExecutable, "#{bin} could not be found."
            end

            if !File.executable?( path )
                raise Error::NotExecutable, "#{bin} found but is not executable."
            end

            path
        end
    end

    def alive?
        @lifeline_pid && Processes::Manager.alive?( @lifeline_pid )
    end

    private

    # @abstract
    def driver
        raise 'Missing implementation'
    end

    # @abstract
    def driver_args
        {}
    end

    # @return   [String]
    #   Path to the driver executable.
    def driver_path
        @driver_path ||= self.class.find_executable( driver )
    end

    def spawn
        return @url if @url

        print_debug 'Spawning engine...'

        port   = nil
        output = ''

        10.times do |i|
            # Clear output of previous attempt.
            output.clear
            port   = Utilities.available_port

            print_debug_level_2 "Attempt ##{i}, chose port number #{port}"
            print_debug_level_2 "Spawning process: #{driver_path}"

            r, w  = IO.pipe
            ri, @kill_process = IO.pipe

            @lifeline_pid = Processes::Manager.spawn(
                "#{Options.paths.executables}/browser.rb",
                executable:   driver_path,
                args:         {
                    port: port
                }.merge( driver_args ),
                without_cuboid: true,
                fork:         false,
                new_pgroup:   true,
                stdin:        ri,
                stdout:       w,
                stderr:       w
            )

            w.close
            ri.close

            print_debug_level_2 'Process started, waiting for WebDriver server...'

            poller = Selenium::WebDriver::SocketPoller.new(
                'localhost', port,
                SPAWN_TIMEOUT
            )

            if !poller.connected?
                print_debug_level_2 '...did not start in time, retrying.'
                kill
                next
            end

            output << r.readpartial( 8192 )
            @pid   = output.scan( /^PID: (\d+)/ ).flatten.first.to_i

            print_debug_level_2 '...up.'

            if !output.empty?
                print_debug_level_2 output
            end

            print_debug 'Engine is ready.'
            break
        end

        # Something went really bad, the browser couldn't be started even after
        # our valiant efforts.
        #
        # Bail out for now and count on the BrowserPool to retry to boot
        # another process ass needed.
        if !@lifeline_pid
            log_error 'Could not start engine process.'
            log_error output

            fail Error::Spawn, 'Could not start the engine process.'
        end

        @url = "http://127.0.0.1:#{port}/"
    end

    def kill
        print_debug_level_2 'Killing engine process...'

        if @kill_process
            begin
                @kill_process.close
                print_debug_level_2 '...done.'
            rescue => e
                print_debug_level_2 '...failed:'
                print_debug_exception( e, 2 )
            end
        else
            print_debug_level_2 '...process not alive in the first place.'
        end

        @kill_process = nil
        @lifeline_pid = nil
        @pid          = nil
        @url          = nil
    end

end

end
end
end
end
end
