=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module HTTP

# @author Tasos Laskos <tasos.laskos@gmail.com>
class Message
    require_relative 'message/scope'

    # @return   [String]
    #   Resource location.
    attr_accessor :url

    # @return   [Headers<String, String>]
    #   HTTP headers as a Hash-like object.
    attr_accessor :headers

    # @return   [String]
    #   {Request}/{Response} body.
    attr_accessor :body

    # @note All options will be sent through the class setters whenever
    #   possible to allow for normalization.
    #
    # @param    [Hash]  options
    #   Message options.
    # @option   options [String]    :url
    #   URL.
    # @option   options [Hash]      :headers
    #   HTTP headers.
    # @option   options [String]    :body
    #   Body.
    def initialize( options = {} )
        update( options )

        fail ArgumentError, 'Missing :url.' if url.to_s.empty?
    end

    def update( options )
        options = options.dup
        @normalize_url = options.delete(:normalize_url)

        # Headers are necessary for subsequent operations to set them first.
        @headers = Headers.new( options[:headers] || {} )

        options.each do |k, v|
            send( "#{k}=", v )
        end
    end

    def headers=( h )
        @headers = Headers.new( h || {} )
    end

    # @return   [Scope]
    def scope
        @scope ||= self.class::Scope.new( self )
    end

    def parsed_url
        # Don't cache this, that's already handled by the URI parser's own cache.
        SCNR::Engine::URI( url )
    end

    def url=( url )
        if @normalize_url || @normalize_url.nil?
            @url = URI.normalize( url ).to_s.freeze
        else
            @url = url.to_s.freeze
        end
    end

end
end
end
