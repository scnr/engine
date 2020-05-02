=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'arachni/rpc'
require_relative '../serializer'

module SCNR::Engine
module RPC
class Client

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Base < Arachni::RPC::Client
    attr_reader :url

    # @param    [String]    url
    #   Server URL in `address:port` format.
    # @param    [String]    token
    #   Optional authentication token.
    # @param    [Hash]   options
    # @option options [Integer]  :connection_pool_size
    # @option options [Integer]  :max_retries
    # @option options [Integer]  :ssl_ca
    # @option options [Integer]  :ssl_pkey
    # @option options [Integer]  :ssl_cert
    def initialize( url, token = nil, options = nil )
        @url = url

        socket, host, port = nil
        if url.include? ':'
            host, port = url.split( ':' )
        else
            socket = url
        end

        @address = host
        @port    = port

        # If given nil use the global defaults.
        options ||= Options.rpc.to_client_options

        super( options.merge(
            serializer: Serializer,
            host:       host,
            port:       port.to_i,
            socket:     socket,
            token:      token
        ))
    end

    def address
        @address
    end

    def port
        @port
    end

end
end
end
end
