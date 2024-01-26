=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine

# Determines whether or not resources (URIs, pages, elements, etc.) are {#out?}
# of the scan {OptionGroups::Scope scope}.
#
# @abstract
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Scope

    # {Scope} error namespace.
    #
    # All {Scope} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < SCNR::Engine::Error
    end

    # @return   [OptionGroups::Scope]
    def options
        Options.scope
    end

    # @return   [Bool]
    #   `true` if the resource is out of scope, `false` otherwise.
    #
    # @abstract
    def out?
    end

end

end
