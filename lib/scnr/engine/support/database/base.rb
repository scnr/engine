=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Support::Database

# Base class for Database data structures
#
# Provides helper methods for data structures to be implemented related to
# objecting dumping, loading, unique filename generation, etc.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @abstract
class Base

    DISK_SPACE_FILE = 'Database_disk_space'

    class <<self
        def disk_directory
            Options.paths.tmpdir
        end
    end

    # @param    [Hash]    options
    #   Any object that responds to 'dump' and 'load'.
    def initialize( options = {} )
        @options = options.dup

        @options[:dumper] ||= Marshal
        @options[:loader] ||= @options[:dumper]

        at_exit do
            clear
        end
    end

    def serialize( obj )
        @options[:dumper].respond_to?( :dump ) ?
            @options[:dumper].dump( obj ) :
            @options[:dumper].call( obj )
    end

    def unserialize( source )
        @options[:loader].respond_to?( :load ) ?
            @options[:loader].load( source ) :
            @options[:loader].call( source )
    end

    def save( location )
        fail 'Not implemented'
    end

    def self._load( location )
        fail 'Not implemented'
    end

end

end
end
