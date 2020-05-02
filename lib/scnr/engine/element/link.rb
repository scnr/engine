=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'base'

module SCNR::Engine::Element

# Represents an auditable link element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Link < Base
    require_relative 'link/dom'

    # Load and include all link-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    # Generic element capabilities.
    include SCNR::Engine::Element::Capabilities::WithSinks
    include SCNR::Engine::Element::Capabilities::WithNode
    include SCNR::Engine::Element::Capabilities::Mutable
    include SCNR::Engine::Element::Capabilities::Inputtable
    include SCNR::Engine::Element::Capabilities::Analyzable
    include SCNR::Engine::Element::Capabilities::Refreshable

    # Link-specific overrides.
    include Capabilities::WithDOM
    include Capabilities::Submittable
    include Capabilities::Auditable

    include SCNR::Engine::Element::Capabilities::Auditable::Buffered
    include SCNR::Engine::Element::Capabilities::Auditable::LineBuffered

    # @param    [Hash]    options
    # @option   options [String]    :url
    #   URL of the page which includes the link.
    # @option   options [String]    :action
    #   Link URL -- defaults to `:url`.
    # @option   options [Hash]    :inputs
    #   Query parameters as `name => value` pairs. If none have been provided
    #   they will automatically be extracted from {#action}.
    def initialize( options )
        super( options )

        self.inputs     = (self.inputs || {}).merge( options[:inputs] || {} )
        @default_inputs = self.inputs.dup.freeze
    end

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#inputs} }`.
    def simple
        { self.action => self.inputs }
    end

    # @return   [String]
    #   Absolute URL with a merged version of {#action} and {#inputs} as a query.
    def to_s
        uri = uri_parse( self.action ).dup
        uri.query = self.inputs.
            map { |k, v| "#{encode(k)}=#{encode(v)}" }.
            join( '&' )
        uri.to_s
    end

    # @see .encode
    def encode( string )
        self.class.encode( string )
    end

    # @see .decode
    def decode( string )
        self.class.decode( string )
    end

    def id
        dom_data ? "#{super}:#{dom_data[:inputs].sort_by { |k,_| k }}" : super
    end

    def to_rpc_data
        data = super
        data.delete 'dom_data'
        data
    end

    class <<self

        # Extracts links from an HTTP response.
        #
        # @param   [SCNR::Engine::HTTP::Response]    response
        #
        # @return   [Array<Link>]
        def from_response( response )
            url = response.url
            [new( url: url )] | from_parser( SCNR::Engine::Parser.new( response ) )
        end

        # @param    [Parser]    parser
        #
        # @return   [Array<Link>]
        def from_parser( parser )
            return [] if parser.body && !in_html?( parser.body )

            e = []
            parser.document.nodes_by_name( :a ) do |link|
                next if too_big?( link['href'] )

                # Both regular and DOM links should include this in href but
                # it's not enough, we need to also check for rewrite rules.
                without_query = !link['href'].include?( '?' )

                href = to_absolute( link['href'], parser.base )
                next if !href

                next if !(parsed_url = SCNR::Engine::URI( href )) ||
                    parsed_url.scope.out?

                if SCNR::Engine::Options.scope.url_rewrites.empty?
                    next if without_query
                else
                    next if without_query && parsed_url.rewrite.query_parameters.empty?
                end

                e << new(
                    url:    parser.url,
                    action: href.freeze,
                    source: link.to_html.freeze
                )
            end
            e
        end

        def in_html?( html )
            html.has_html_tag? 'a', /\?.*=/
        end

        def encode( string )
            SCNR::Engine::HTTP::Request.encode string
        end

        def decode( string )
            SCNR::Engine::URI.decode( string )
        end
    end


    private

    def http_request( opts, &block )
        self.method != :get ?
            http.post( self.action, opts, &block ) :
            http.get( self.action, opts, &block )
    end

end
end

SCNR::Engine::Link = SCNR::Engine::Element::Link
