=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'watir'
require_relative '../../../../selenium/webdriver/remote/typhoeus'

module SCNR::Engine
class Browser
class Engines
class Base
module Parts

module WebDriver

    # @abstract
    def console
        raise 'Missing implementation'
    end

    # @return   [Watir::Browser]
    #   Watir driver interface.
    def watir
        @watir ||= ::Watir::Browser.new( selenium )
    end

    # @return   [Selenium::WebDriver::Driver]
    #   Selenium driver interface.
    def selenium
        return @selenium if @selenium

        # Using Typhoeus for Selenium results in memory violation errors on
        # Windows, so use the default Net::HTTP-based client.
        if SCNR::Engine.windows?
            client = Selenium::WebDriver::Remote::Http::Default.new
            client.read_timeout = Options.dom.job_timeout
            client.open_timeout = Options.dom.job_timeout

        # However, using the default client results in Threads being used
        # because Net::HTTP uses them for timeouts, and Threads are resource
        # intensive (around 1MB per Thread).
        #
        # So, if we're not on Windows, use Typhoeus.
        else
            client = Selenium::WebDriver::Remote::Http::Typhoeus.new
            client.timeout = Options.dom.job_timeout
        end

        10.times do |i|
            begin
                @selenium = webdriver.new(
                    # We need to start our own process because Selenium's way
                    # sometimes gives us zombies.
                    url:                  spawn,
                    desired_capabilities: capabilities,
                    options:              options,
                    http_client:          client
                )

                selenium_setup

                return @selenium
            rescue Selenium::WebDriver::Error::WebDriverError,
                Errno::ECONNREFUSED, Timeout::Error => e

                # ap e
                # ap e.backtrace
                # ::Process.kill 'KILL', ::Process.pid

                shutdown
                print_debug_exception e
            end
        end

        fail Error, 'Could not initialize Selenium.'
    end

    def refresh
        if @selenium
            @selenium.quit rescue nil
            @selenium = nil
        end

        if @watir
            @watir.quit rescue nil
            @watir = nil
        end

        nil
    end

    private

    # @abstract
    def webdriver
        raise 'Missing implementation'
    end

    # @abstract
    def capabilities
        raise 'Missing implementation'
    end

    # @abstract
    def selenium_setup
    end

    def default_capabilities
        {
            # Selenium tries to be helpful by including screenshots for errors
            # in the JSON response. That's not gonna fly here as parsing lots of
            # massive JSON responses at the same time will have a significant
            # impact on performance.
            takes_screenshot:      false,
            accept_ssl_certs:      true,
            accept_insecure_certs: true
        }
    end

    def start_webdriver
        # Will start #selenium on-demand, which will #spawn on-demand.
        watir
    end

end

end
end
end
end
end
