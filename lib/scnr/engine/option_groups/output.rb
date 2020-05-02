=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::OptionGroups

# {SCNR::Engine::UI::Output} options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Output < SCNR::Engine::OptionGroup

    # @return   [Bool]
    #   `true` if the output of the RPC instances should be redirected to a
    #   file, `false` otherwise.
    attr_accessor :reroute_to_logfile

end
end
