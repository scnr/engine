=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Support::Cache

# Least Recently Pushed cache implementation.
#
# Discards the least recently pushed entries, in order to make room for newer ones.
#
# This is the cache with best performance across the board.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class LeastRecentlyPushed < Base

    private

    def prune
        @cache.delete( @cache.first.first )
    end

end
end
end
