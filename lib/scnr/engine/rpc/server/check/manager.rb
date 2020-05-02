=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine

require Options.paths.lib + 'check/manager'

module RPC
class Server

# @private
module Check

# We need to extend the original Manager and re-declare its inherited methods
# which are required over RPC.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Manager < ::SCNR::Engine::Check::Manager

    # make these inherited methods visible again
    private :load, :available, :loaded, :load_all
    public :load, :available, :loaded, :load_all

    def load( checks )
        @framework.options.checks = super( checks )
    end

end

end
end
end
end
