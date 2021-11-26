=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
class Engines

class Chrome < Base

    REQUIREMENTS = {
        'chrome'       => {
            min: 96,
            max: 96
        },
        'chromedriver' => {
            min: 96,
            max: 96
        }
    }

    DRIVER = 'chromedriver'

    # http://peter.sh/experiments/chromium-command-line-switches/
    BROWSER_ARGS = [
        '--allow-running-insecure-content',
        '--disable-web-security',
        '--reduce-security-for-testing',
        '--ignore-certificate-errors'
    ]

    REQUEST_BLACKLIST = []


    def self.requirements
        synchronize do
            # We want the exception every time so we put this before the lazy
            # retrieval of the rest of the info.
            if SCNR::Engine.mac?
                browser_bin = self.find_executable( 'Google Chrome' )
            else
                browser_bin = begin
                                  self.find_executable( 'google-chrome' )
                              rescue
                                  self.find_executable( 'google-chrome-beta' )
                              rescue
                                  self.find_executable( 'chrome' )
                              end
            end

            driver_bin = self.find_executable( DRIVER )

            if @requirements
                @requirements['chrome'][:binary] = browser_bin
                return @requirements
            end
            @requirements = REQUIREMENTS.dup
            @requirements['chrome'][:binary] = browser_bin

            if SCNR::Engine.windows?
                # In the same dir as the executable there's a dir with the version
                # as its name.
                version = nil
                Dir.glob( "#{File.dirname( @requirements['chrome'][:binary] )}/*" ).each do |d|
                    version = File.basename( d ).scan( /^\d+?\./ ).first.to_i
                    break if version > 0
                end

                @requirements['chrome'][:current] = version
            else
                @requirements['chrome'][:current] =
                  `"#{@requirements['chrome'][:binary]}" --version`.scan( /\d+/ ).first.to_i
            end

            @requirements['chromedriver'][:current] =
              `"#{driver_bin}" --version`.scan( /[\d\.]+/ ).first.to_f

            @requirements
        end
    end

    def window_width
        browser.javascript.run( 'return window.screen.width' )
    end

    def window_height
        browser.javascript.run( 'return window.screen.height' )
    end

    def touch?
        browser.javascript.run( 'return navigator.maxTouchPoints > 0' )
    end

    def console
        selenium.manage.logs.get(:browser)
    end

    private

    def webdriver
        Selenium::WebDriver::Chrome::Driver
    end

    def driver
        DRIVER
    end

    def request_blacklist
        REQUEST_BLACKLIST
    end

    def options
        proxy_uri = URI( proxy.url )

        args = BROWSER_ARGS + [
          "--proxy-server=#{proxy_uri.host}:#{proxy_uri.port}"
        ]
        args << '--headless' if !@options[:visible]

        Selenium::WebDriver::Chrome::Options.new(
          args: args,
          binary: self.class.requirements['chrome'][:binary],
          emulation: {
            userAgent:     @options[:user_agent],
            deviceMetrics: {
              width:      @options[:width],
              height:     @options[:height],
              pixelRatio: @options[:pixel_ratio],
              touch:      @options[:touch]
            }
          }
        )
    end

end

end
end
end
