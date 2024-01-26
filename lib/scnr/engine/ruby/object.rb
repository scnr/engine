=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Overloads the {Object} class providing a {#deep_clone} method.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Object

    # Deep-clones self using a Marshal dump-load.
    #
    # @return   [Object]
    #   Duplicate of self.
    def deep_clone
        Marshal.load( Marshal.dump( self ) )
    end

    def rpc_clone
        if self.class.respond_to?( :from_rpc_data )
            self.class.from_rpc_data(
                SCNR::Engine::RPC::Serializer.serializer.load(
                    SCNR::Engine::RPC::Serializer.serializer.dump( to_rpc_data )
                )
            )
        else
            SCNR::Engine::RPC::Serializer.serializer.load(
                SCNR::Engine::RPC::Serializer.serializer.dump( self )
            )
        end
    end

    def to_rpc_data_or_self
        respond_to?( :to_rpc_data ) ? to_rpc_data : self
    end

end
