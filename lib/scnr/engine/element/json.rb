=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'rack'
require 'rack/typhoeus/middleware/params_decoder'
require_relative 'base'

module SCNR::Engine::Element

# Represents an auditable JSON element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class JSON < Base
    # Load and include all JSON-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    # Generic element capabilities.
    include SCNR::Engine::Element::Capabilities::WithSinks
    include SCNR::Engine::Element::Capabilities::Auditable
    include SCNR::Engine::Element::Capabilities::Auditable::Buffered
    include SCNR::Engine::Element::Capabilities::Auditable::LineBuffered
    include SCNR::Engine::Element::Capabilities::Submittable
    include SCNR::Engine::Element::Capabilities::Analyzable
    include SCNR::Engine::Element::Capabilities::WithSource

    # JSON-specific overrides.
    include Capabilities::Inputtable
    include Capabilities::Mutable

    # @param    [Hash]    options
    # @option   options [String]    :url
    #   URL of the page which includes the link.
    # @option   options [String]    :action
    #   Link URL -- defaults to `:url`.
    # @option   options [Hash]    :inputs
    #   Query parameters as `name => value` pairs. If none have been provided
    #   they will automatically be extracted from {#action}.
    def initialize( options )
        self.http_method = options[:method] || :post

        super( options )

        self.inputs = (self.inputs || {}).merge( options[:inputs] || {} )

        if @source && self.inputs.empty?
            self.inputs = ::JSON.load( self.source )
        end

        @default_inputs = self.inputs.dup.freeze
    end

    #   JSON formatted {#inputs}.
    def to_json
        @inputs.to_json
    end

    def to_h
        super.merge( source: @source )
    end

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#inputs} }`.
    def simple
        { self.action => self.inputs }
    end

    # @see .encode
    def encode( *args )
        self.class.encode( *args )
    end

    # @see .decode
    def decode( *args )
        self.class.decode( *args )
    end

    def dup
        super.tap { |e| e.inputs = @inputs.rpc_clone }
    end

    class <<self

        # No-op
        def encode( v )
            v
        end

        # No-op
        def decode( v )
            v
        end

        # Extracts JSON elements from an HTTP request.
        #
        # @param   [SCNR::Engine::HTTP::Request]    request
        #
        # @return   [JSON, nil]
        def from_request( url, request )
            return if !request.body.is_a?( String ) || request.body.empty?
            return if too_big?( request.body )

            data =  begin
                ::JSON.load( request.body )
            rescue ::JSON::ParserError
            end

            return if !data.is_a?( Hash ) || data.empty?

            new(
                url:    url,
                action: request.url,
                method: request.method,
                inputs: data,
                source: request.body
            )
        end

    end

    private

    def http_request( opts, &block )
        opts = opts.dup
        opts.delete :parameters
        opts.merge!(
            headers: {
                'Content-Type' => 'application/json'
            }
        )

        opts[:body]   = self.to_json
        opts[:method] = self.http_method
        http.request( self.action, opts, &block )
    end

end
end

SCNR::Engine::JSON = SCNR::Engine::Element::JSON
