=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::OptionGroups

# Holds options for {RPC::Server::Queue} servers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Queue < SCNR::Engine::OptionGroup

    # @return   [String]
    #   URL of a {RPC::Server::Queue}.
    attr_accessor :url

    # @return   [Array<Integer>]
    #   Range of ports to use when spawning instances, first entry should be
    #   the lowest port number, last the max port number.
    attr_accessor :instance_port_range

    # @return   [Float]
    #   How regularly to check for scan statuses.
    attr_accessor :ping_interval

    set_defaults(
        ping_interval:       5.0,
        instance_port_range: [1025, 65535]
    )

end
end
