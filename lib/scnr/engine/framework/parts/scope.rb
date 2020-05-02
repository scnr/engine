=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Framework
module Parts

# Provides scope helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Scope

    # @return   [Bool]
    #   `true` if the {OptionGroups::Scope#page_limit} has been reached,
    #   `false` otherwise.
    def page_limit_reached?
        options.scope.page_limit_reached?( sitemap.size )
    end

    def crawl?
        options.scope.crawl? && options.scope.restrict_paths.empty?
    end

    # @return   [Bool]
    #   `true` if the framework can process more pages, `false` is scope limits
    #   have been reached.
    def accepts_more_pages?
        crawl? && !page_limit_reached?
    end

end

end
end
end
