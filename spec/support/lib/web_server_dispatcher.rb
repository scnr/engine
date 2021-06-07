=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative '../../support/helpers/paths'
require_relative 'web_server_manager'
require 'arachni/rpc'

# @note Needs `ENV['WEB_SERVER_DISPATCHER']` in the format of `host:port`.
#
# Exposes the {WebServerManager} over RPC.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class WebServerDispatcher

    def initialize( options = {} )
        host, port = ENV['WEB_SERVER_DISPATCHER'].split( ':' )

        manager = WebServerManager.instance
        manager.address = host

        rpc = SCNR::Engine::RPC::Server.new( host: host, port: port.to_i )
        rpc.add_handler( 'server', manager )
        rpc.run
    end

end
