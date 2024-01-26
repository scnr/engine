=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Simple cookie collector
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.2.1
class SCNR::Engine::Plugins::CookieCollector < SCNR::Engine::Plugin::Base

    def prepare
        @cookies = []
    end

    def suspend
        @cookies
    end

    def restore( cookies )
        @cookies = cookies
    end

    def run
        http.on_new_cookies do |cookies, response|
            cookies_hash = cookies.inject({}) { |h, c| h.merge!( c.simple ); h }
            update( filter( cookies_hash ), response )
        end

        wait_while_framework_running
    end

    def update( cookies, response )
        return if cookies.empty? || !update?( cookies )

        response_hash = response.to_h
        response_hash.delete( :body )
        response_hash.delete( :headers_string )

        r_h = response_hash.my_stringify_keys
        r_h['headers']['Set-Cookie'] = [r_h['headers']['Set-Cookie']].flatten.compact

        @cookies << {
            'time'     => Time.now.to_s,
            'response' => r_h,
            'cookies'  => cookies
        }
    end

    def update?( cookies )
        return true if @cookies.empty?
        cookies.each { |k, v| return true if @cookies.last['cookies'][k] != v }
        false
    end

    def clean_up
        register_results( @cookies )
    end

    def filter( cookies )
        @filter ||= Regexp.new( options[:filter] ) if options[:filter]

        return cookies if !@filter
        cookies.select { |name, _| name =~ @filter }
    end

    def self.info
        {
            name:        'Cookie collector',
            description: %q{
Monitors and collects cookies while establishing a timeline of changes.

**WARNING**: Highly discouraged when the audit includes cookies. It will log
thousands of results leading to a huge report, highly increased memory
consumption and CPU usage.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.1',
            options:     [
                Options::String.new( :filter,
                    description: 'Pattern to use to determine which cookies to ' +
                                  'log, based on cookie name.'
                )
            ]
        }
    end

end
