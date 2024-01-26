=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'watir'

# Prevent this intermitent exception:
#   constant Selenium::WebDriver::Remote::COMMANDS not defined
require 'selenium/webdriver/remote/commands'

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

        10.times do |i|
            begin
                @selenium = Selenium::WebDriver.for(
                    :remote,

                    # We need to start our own process because Selenium's way
                    # sometimes gives us zombies.
                    url:          self.spawn,
                    capabilities: options,
                    http_client:  Selenium::WebDriver::Remote::Http::Typhoeus.new
                )

                selenium_setup

                return @selenium
            rescue Selenium::WebDriver::Error::WebDriverError,
                Errno::ECONNREFUSED, Timeout::Error => e

                print_debug_exception e
                self.shutdown
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
    def options
        raise 'Missing implementation'
    end

    # @abstract
    def selenium_setup
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
