=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Page

# Determines the {Scope scope} status of {Page}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Scope < HTTP::Response::Scope

    class <<self
        include Support::Mixins::Decisions

        query :select
        query :reject
    end
    ask!

    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < HTTP::Response::Scope::Error
    end

    def initialize( page )
        # We're passing the page itself instead of the Page#response because we
        # want it to use the (possibly browser-evaluated) Page#body for content
        # scope checks.
        super page

        @page = page
    end

    # @note Also takes into account the {HTTP::Response::Scope} of the {Page#response}.
    #
    # @return   [Bool]
    #   `true` if the {Page} is out of {OptionGroups::Scope scope},
    #   `false`otherwise.
    #
    # @see #dom_depth_limit_reached?
    def out?
        (Scope.reject?( @page ) || dom_depth_limit_reached? || super) ||
          (Scope.ask_select? && !Scope.select?( @page ))
    end

    # @return   [Bool]
    #   `true` if the {Page::DOM#depth} is greater than
    #   {OptionGroups::Scope#dom_depth_limit} `false` otherwise.
    #
    # @see OptionGroups::Scope#dom_depth_limit
    def dom_depth_limit_reached?
        options.dom_depth_limit && @page.dom.depth > options.dom_depth_limit
    end

end

end
end
