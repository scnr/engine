=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'ostruct'
require 'arachni/rpc'
require_relative '../serializer'

module SCNR::Engine
module RPC
class Server

# RPC server class
#
# @private
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Base < Arachni::RPC::Server

    # @param    [Hash]   options
    # @option options [Integer]  :host
    # @option options [Integer]  :port
    # @option options [Integer]  :socket
    # @option options [Integer]  :ssl_ca
    # @option options [Integer]  :ssl_pkey
    # @option options [Integer]  :ssl_cert
    # @param    [String]    token
    #   Optional authentication token.
    def initialize( options = nil, token = nil )

        # If given nil use the global defaults.
        options ||= Options.rpc.to_server_options
        @options = options

        super(options.merge(
            serializer: Serializer,
            token:      token
        ))
    end

    def address
        @options[:external_address] || @options[:host]
    end

    def port
        @options[:port]
    end

    def url
        return @options[:socket] if @options[:socket]

        "#{address}:#{port}"
    end

    def start
        super
        @ready = true
    end

    def ready?
        @ready ||= false
    end

end

end
end
end
