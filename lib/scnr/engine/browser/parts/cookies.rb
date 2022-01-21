=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative '../engines/base'

module SCNR::Engine
class Browser
module Parts

module Cookies

    # @return   [Array<Cookie>]
    def cookies
        js_cookies = begin
             # Selenium doesn't tell us if cookies are HttpOnly, so we need to
             # figure this out ourselves, by checking for JS visibility.
            javascript.run( 'return document.cookie' )

        # We may not have a page.
        rescue Selenium::WebDriver::Error::WebDriverError
            ''
        end

        current_url = self.url

        # TODO: Chrome returns no cookies for '.localhost' (or is it a
        # bug and it's all subdomains?) and Firefox just converts '.localhost'
        # to 'localhost', is this only for localhost or general bug?
        selenium.manage.all_cookies.map do |c|
            c[:httponly] = !js_cookies.include?( c[:name].to_s )
            c[:path]     = c[:path].gsub( /\/+/, '/' )

            if c[:expires]
                # TODO: In Firefox session cookies return very large
                # expiration date:
                #  https://github.com/mozilla/geckodriver/issues/1000
                #
                # TODO: In Chrome expiration dates are very close to epoch.
                if c[:expires].year < 292277026596
                    c[:expires] = Time.parse( c[:expires].to_s )
                else
                    c[:expires] = nil
                end
            end

            c[:raw_name]  = c[:name].to_s
            c[:raw_value] = c[:value].to_s

            c[:name]  = Cookie.decode( c[:raw_name].to_s )
            c[:value] = Cookie.value_to_v0( c[:raw_value].to_s )

            Cookie.new c.merge( url: @last_url || current_url )
        end
    end

    private

    def load_cookies( url, cookies = {} )
        # First clears the browser's cookies and then tricks it into accepting
        # the system cookies for its cookie-jar.
        #
        # Well, it doesn't really clear the browser's cookie-jar, but that's
        # not necessary because whatever cookies the browser has have already
        # gotten into the system-wide cookiejar, and since we're passing
        # all applicable cookies to the browser the end result will be that
        # it'll have the wanted values.

        url = normalize_url( url )

        set_cookies = {}
        SCNR::Engine::HTTP::Client.cookie_jar.for_url( url ).each do |cookie|
            cookie = cookie.dup
            set_cookies[cookie.name] = cookie
        end

        cookies.each do |name, value|
            if set_cookies[name]
                set_cookies[name] = set_cookies[name].dup

                # Don't forget this, otherwise the #to_set_cookie call will
                # return the original raw data.
                set_cookies[name].affected_input_name = name
                set_cookies[name].update( name => value )
            else
                set_cookies[name] = Cookie.new( url: url, inputs: { name => value } )
            end
        end

        return if set_cookies.empty? &&
            Options.dom.local_storage.empty? &&
            Options.dom.session_storage.empty?

        set_cookie = set_cookies.values.map(&:to_set_cookie)
        print_debug_level_2 "Setting cookies: #{set_cookie}"

        body = ''
        if Options.dom.local_storage.any?
            body << <<EOJS
                <script>
                    var data = #{Options.dom.local_storage.to_json};

                    for( prop in data ) {
                        localStorage.setItem( prop, data[prop] );
                    }
                </script>
EOJS
        end

        if Options.dom.session_storage.any?
            body << <<EOJS
                <script>
                    var data = #{Options.dom.session_storage.to_json};

                    for( prop in data ) {
                        sessionStorage.setItem( prop, data[prop] );
                    }
                </script>
EOJS
        end

        selenium.navigate.to preload( SCNR::Engine::HTTP::Response.new(
            code:    200,
            url:     "#{url}/set-cookies-#{request_token}",
            body:    body,
            headers: {
                'Set-Cookie' => set_cookie
            }
        ))
    end

    def update_cookies
        SCNR::Engine::HTTP::Client.update_cookies self.cookies
    end

end

end
end
end
