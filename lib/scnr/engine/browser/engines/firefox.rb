=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
class Engines

class Firefox < Base

    REQUIREMENTS = {
        'firefox'     => {
            min: 87,
            max: 88
        },
        'geckodriver' => {
            min: 0.29,
            max: 0.29
        }
    }

    DRIVER = 'geckodriver'

    BROWSER_PREFERENCES = {
        'browser.cache.disk.enable' => true,

        # Manual
        'network.proxy.type'          => 1,
        # Enable proxy for localhost.
        'network.proxy.no_proxies_on' => '',

        'network.captive-portal-service.enabled' => false,

        # Allow loading HTTP resources over HTTPS, we need
        # this too for our own JS env.
        'security.mixed_content.block_active_content' => false,

        'services.sync.engine.addons' => false,

        'app.update.auto'    => false,
        'app.update.enabled' => false,

        'media.gmp-manager.url' => '',

        'extensions.update.enabled' => false,

        'privacy.trackingprotection.introURL' => '',

        'browser.search.geoip.url'                         => '',
        'browser.geolocation.warning.infoURL'              => '',
        'browser.safebrowsing.provider.mozilla.gethashURL' => '',
        'browser.safebrowsing.provider.mozilla.updateURL'  => ''
    }

    REQUEST_BLACKLIST = [
        /ciscobinary\.openh264\.org/
    ]

    def self.requirements
        synchronize do
            # We want the exception every time so we put this before the lazy
            # retrieval of the rest of the info.
            browser_bin = self.find_executable( 'firefox' )
            driver_bin  = self.find_executable( DRIVER )

            if @requirements
                @requirements['firefox'][:binary] = browser_bin
                return @requirements
            end

            @requirements = REQUIREMENTS.dup
            @requirements['firefox'][:binary] = browser_bin

            if SCNR::Engine.windows?
                @requirements['firefox'][:current] =
                  `"#{@requirements['firefox'][:binary]}" --version | more`.
                    scan( /\d+/ ).first.to_i
            else
                @requirements['firefox'][:current] =
                  `"#{@requirements['firefox'][:binary]}" --version`.
                    scan( /\d+/ ).first.to_i
            end

            @requirements['geckodriver'][:current] =
              `"#{driver_bin}" --version`.scan( /[\d\.]+/ ).first.to_f

            @requirements
        end
    end

    def window_width
        browser.javascript.run( 'return window.outerWidth' )
    end

    def window_height
        browser.javascript.run( 'return window.outerHeight' )
    end

    def touch?
        browser.javascript.run( 'return ("ontouchstart" in document.documentElement)' )
    end

    def version
        @version ||= `firefox --version`.scan( /\d+/ ).first.to_i
    end

    private

    def webdriver
        Selenium::WebDriver::Firefox::Marionette::Driver
    end

    def driver
        DRIVER
    end

    def request_blacklist
        REQUEST_BLACKLIST
    end

    def capabilities
        Selenium::WebDriver::Remote::Capabilities.firefox(
            default_capabilities.merge(
                binary: self.class.requirements['firefox'][:binary],
            )
        )
    end

    def options
        proxy_uri = URI( proxy.url )

        args = []
        args << '--headless' if !@options[:visible]

        Selenium::WebDriver::Firefox::Options.new(
          args:   args,
          prefs: BROWSER_PREFERENCES.merge(
              'general.useragent.override'   => @options[:user_agent],
              'dom.w3c_touch_events.enabled' => @options[:touch] ? 1 : 0,
              'dom.w3c_touch_events.expose'  => @options[:touch] ? 1 : 0,
              'layout.css.devPixelsPerPx'    => @options[:pixel_ratio].to_s,

              'network.proxy.http'      => proxy_uri.host,
              'network.proxy.http_port' => proxy_uri.port,
              'network.proxy.ssl'       => proxy_uri.host,
              'network.proxy.ssl_port'  => proxy_uri.port
          )
        )
    end

    def selenium_setup
        selenium.manage.window.resize_to(
            @options[:width],
            @options[:height]
        )
    end

end

end
end
end
