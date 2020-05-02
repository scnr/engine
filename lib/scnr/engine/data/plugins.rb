=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'monitor'

module SCNR::Engine
class Data

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Plugins
    include UI::Output
    include MonitorMixin

    # @return   [Hash<Symbol=>Hash>]
    #   Plugin results.
    attr_reader :results

    def initialize
        super

        @results = {}
    end

    def statistics
        {
            names: @results.keys
        }
    end

    # Registers plugin results.
    #
    # @param    [SCNR::Engine::Plugin::Base]    plugin
    #   Instance of a plugin.
    # @param    [Object]    results
    def store( plugin, results )
        synchronize do
            @results[plugin.shortname.to_sym] = plugin.info.merge( results: results )
        end
    end

    def dump( directory )
        %w(results).each do |type|
            send(type).each do |plugin, data|
                result_directory = "#{directory}/#{type}/"
                FileUtils.mkdir_p( result_directory )

                IO.binwrite( "#{result_directory}/#{plugin}", Marshal.dump( data ) )
            end
        end
    end

    def self.load( directory )
        plugins = new

        %w(results).each do |type|
            Dir["#{directory}/#{type}/*"].each do |plugin_directory|
                plugin = File.basename( plugin_directory ).to_sym
                plugins.send(type)[plugin] = Marshal.load( IO.binread( plugin_directory ) )
            end
        end

        plugins
    end

    def clear
        @results.clear
    end

end
end
end
