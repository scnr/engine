=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Support::Cache

# Random Replacement cache implementation.
#
# Discards entries at random in order to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class RandomReplacement < Base

    private

    def prune
        @cache.delete( @cache.keys.sample )
    end

end

end
end
