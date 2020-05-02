require Options.paths.lib  + 'rpc/server/queue'

Arachni::Reactor.global.run do
    RPC::Server::Queue.new
end
