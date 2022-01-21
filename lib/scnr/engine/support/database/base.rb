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

        def reset
            @@disk_space = 0
            set_disk_space @@disk_space
        end

        def increment_disk_space( int )
            set_disk_space @@disk_space + int
        end

        def decrement_disk_space( int )
            set_disk_space @@disk_space - int
        end

        def disk_space
            @@disk_space
        end

        def disk_directory
            Options.paths.tmpdir
        end

        def disk_space_file
            disk_space_file_for Process.pid
        end

        def disk_space_for( pid )
            return 0 if !Dir.exists?( Options.paths.tmp_dir_for( pid ) )

            IO.read( disk_space_file_for( pid ) ).to_i
        end

        def disk_space_file_for( pid )
            "#{Options.paths.tmp_dir_for( pid )}/#{DISK_SPACE_FILE}"
        end

        private

        def set_disk_space( int )
            if !File.exist?( disk_directory )
                # Could be caught in #at_exit callbacks, the tmpdir has already
                # been deleted.
                return
            end

            synchronize do
                @@disk_space = int
                IO.write( disk_space_file, @@disk_space.to_s )
            end
        end

        def synchronize( &block )
            (@@mutex ||= Mutex.new).synchronize( &block )
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

    def unserialize( source )
        @options[:loader].respond_to?( :load ) ?
            @options[:loader].load( source ) :
            @options[:loader].call( source )
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
        self.class.increment_disk_space File.size( p )
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

        self.class.decrement_disk_space File.size( filepath )
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
        # Should be unique enough...
        ("#{self.class.disk_directory}/#{self.class.name}_#{object_id}_" <<
            @filename_counter.to_s).gsub( '::', '_' )
    ensure
        @filename_counter += 1
    end

end

end
end
