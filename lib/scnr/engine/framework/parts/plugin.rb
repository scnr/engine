=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Framework
module Parts

# Provides a {SCNR::Engine::Plugin::Manager} and related helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Plugin

    # @return   [SCNR::Engine::Plugin::Manager]
    attr_reader :plugins

    def initialize
        super
        @plugins = SCNR::Engine::Plugin::Manager.new
    end

    # @return    [Array<Hash>]
    #   Information about all available {Plugins}.
    def list_plugins( patterns = nil )
        loaded = @plugins.loaded

        begin
            @plugins.clear
            @plugins.available.map do |plugin|
                path = @plugins.name_to_path( plugin )
                next if patterns && !@plugins.matches_globs?( path, patterns )

                @plugins[plugin].info.merge(
                    options:   @plugins[plugin].info[:options] || [],
                    shortname: plugin,
                    path:      path,
                    author:    [@plugins[plugin].info[:author]].
                                   flatten.map { |a| a.strip }
                )
            end.compact
        ensure
            @plugins.clear
            @plugins.load loaded
        end
    end

end

end
end
end
