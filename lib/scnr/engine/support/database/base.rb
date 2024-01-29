=begin
    Copyright 2024 Ecsypno Single Member P.C.

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

    class <<self

        def reset
        end

        def disk_directory
            Options.paths.tmpdir
        end
    end
    reset

    # @param    [Hash]    options
    #   Any object that responds to 'dump' and 'load'.
    def initialize( options = {} )
        @options = options.dup

        @options[:dumper] ||= Marshal
        @options[:loader] ||= @options[:dumper]

        @filename_counter = 0

        at_exit do
            clear
        end
    end

    def serialize( obj, io )
        @options[:dumper].respond_to?( :dump ) ?
            @options[:dumper].dump( obj, io ) :
            @options[:dumper].call( obj, io )
    end

    def unserialize( io )
        @options[:loader].respond_to?( :load ) ?
            @options[:loader].load( io ) :
            @options[:loader].call( io )
    end

    private

    # Dumps the object to a unique file and returns its path.
    #
    # The path can be used as a reference to the original value
    # by way of passing it to load().
    #
    # @param    [Object]    obj
    #
    # @return   [String]
    #   Filepath
    def dump( obj )
        p = nil
        File.open( get_unique_filename, 'wb' ) do |f|
            serialize( obj, f )
            p = f.path
        end
        p
    end

    # Loads the object stored in filepath.
    #
    # @param    [String]    filepath
    #
    # @return   [Object]
    def load( filepath )
        File.open( filepath, 'rb' ) do |f|
            unserialize( f )
        end
    end

    # Deletes a file.
    #
    # @param    [String]    filepath
    def delete_file( filepath )
        return if !File.exist?( filepath )
        File.delete( filepath )
    end

    # Loads the object in file and then removes it from the file-system.
    #
    # @param    [String]    filepath
    #
    # @return   [Object]
    def load_and_delete_file( filepath )
        obj = load( filepath )
        delete_file( filepath )
        obj
    end

    def get_unique_filename
        "#{self.class.disk_directory}/#{object_id}.#{@filename_counter}"
    ensure
        @filename_counter += 1
    end

end

end
end
