=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Plugins::UncommonHeaders < SCNR::Engine::Plugin::Base

    COMMON = Set.new([
         'content-type',
         'content-length',
         'server',
         'connection',
         'accept-ranges',
         'age',
         'allow',
         'cache-control',
         'content-encoding',
         'content-language',
         'content-range',
         'date',
         'etag',
         'expires',
         'last-modified',
         'location',
         'pragma',
         'proxy-authenticate',
         'set-cookie',
         'trailer',
         'transfer-encoding',
         'keep-alive',
         'content-disposition'
    ])

    def prepare
        @headers_per_url = Hash.new do |h, url|
            h[url] = {}
        end
    end

    def restore( headers )
        prepare
        @headers_per_url.merge!( headers )
    end

    def suspend
        @headers_per_url
    end

    def run
        http.on_complete do |response|
            next if response.scope.out?

            headers = response.headers.
                select { |name, _| !COMMON.include?( name.to_s.downcase ) }
            next if headers.empty?

            @headers_per_url[response.url].merge! headers
        end

        wait_while_framework_running

        # The merge is here to remove the default hash Proc which cannot be
        # serialized.
        register_results( {}.merge( @headers_per_url ) )
    end

    def self.info
        {
            name:        'Uncommon headers',
            description: %q{
Intercepts HTTP responses and logs uncommon headers.

Common headers are:

%s

} % COMMON.to_a.map { |h| "* #{h}" }.join("\n"),
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.3'
        }
    end

end
