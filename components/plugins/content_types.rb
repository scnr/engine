=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Logs content-types of all server responses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Plugins::ContentTypes < SCNR::Engine::Plugin::Base

    def prepare
        @results = {}
        @logged  = SCNR::Engine::Support::Filter::Set.new
    end

    def restore( data )
        @results = data[:results]
        @logged  = data[:logged]
    end

    def suspend
        { results: @results, logged: @logged }
    end

    def run
        http.on_complete do |response|
            next if skip?( response )

            type = response.headers.content_type
            type = type.join( ' - ' ) if type.is_a?( Array )

            @results[type] ||= []
            @results[type] << {
                'url'        => response.url,
                'method'     => response.request.method.to_s.upcase,
                'parameters' => response.request.parameters
            }

            log( response )
        end
    end

    def skip?( response )
        response.scope.out? || logged?( response ) ||
            response.headers.content_type.to_s.empty? || !log?( response )
    end

    def log?( response )
        @exclude ||= Regexp.new( options[:exclude] )
        options[:exclude].empty? ||
            !response.headers.content_type.to_s.match( @exclude )
    end

    def logged?( response )
        @logged.include?( log_id( response ) )
    end

    def log( response )
        @logged << log_id( response )
    end

    def log_id( response )
        response.request.method.to_s.upcase + response.url
    end

    def clean_up
        wait_while_framework_running
        register_results( @results )
    end

    def self.info
        {
            name:        'Content-types',
            description: %q{
Logs content-types of server responses.

It can help you categorize and identify publicly available file-types which in
turn can help you identify accidentally leaked files.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.7',
            options:     [
                Options::String.new( :exclude,
                    description: 'Exclude content-types that match this regular expression.',
                    default:     'text'
                )
            ]
        }
    end

end
