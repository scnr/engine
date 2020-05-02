=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine

require Options.paths.lib + 'plugin/manager'

module RPC
class Server

# @private
module Plugin

# We need to extend the original Manager and redeclare its inherited methods
# which are required over RPC.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Manager < ::SCNR::Engine::Plugin::Manager

    # make these inherited methods visible again
    private :available, :loaded, :results
    public  :available, :loaded, :results

    def load( plugins )
        if plugins.is_a?( Array )
            h = {}
            plugins.each { |p| h[p] = @framework.options.plugins[p] || {} }
            plugins = h
        end

        plugins.each do |plugin, opts|
            prepare_options( plugin, self[plugin], opts )
        end

        @framework.options.plugins.merge!( plugins )
        super( plugins.keys )
    end

end

end
end
end
end
