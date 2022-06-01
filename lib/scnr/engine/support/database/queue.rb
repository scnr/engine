=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'gdbm'

module SCNR::Engine
module Support::Database

# Flat-file Queue implementation
#
# Behaves pretty much like a Ruby Queue however it transparently serializes and
# saves its entries to the file-system under the OS's temp directory **after**
# a specified {#max_buffer_size} (for in-memory entries) has been exceeded.
#
# It's pretty useful when you want to reduce memory footprint without
# having to refactor any code since it behaves just like a Ruby Queue
# implementation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Queue < Base

    # @see SCNR::Engine::Database::Base#initialize
    def initialize( options = {} )
        super( options )

        @db = GDBM.new( "#{self.class.disk_directory}/#{object_id}.db" )

        @waiting = []
        @mutex   = Mutex.new

        @push_counter = 0
    end

    # @note Defaults to {DEFAULT_MAX_BUFFER_SIZE}.
    #
    # @return   [Integer]
    #   How many entries to keep in memory before starting to off-load to disk.
    def max_buffer_size
        @max_buffer_size
    end

    # @param    [Object]    obj
    #   Object to add to the queue.
    def <<( obj )
        synchronize do
            k = @push_counter.to_s
            @db[k] = serialize( obj )

            @push_counter += 1
            begin
                t = @waiting.shift
                t.wakeup if t
            rescue ThreadError
                retry
            end
        end
    end
    alias :push :<<
    alias :enq :<<

    # @return   [Object]
    #   Removes an object from the queue and returns it.
    def pop( non_block = false )
        synchronize do
            loop do
                if @db.empty?
                    raise ThreadError, 'queue empty' if non_block
                    @waiting.push Thread.current
                    @mutex.sleep
                else
                    return unserialize( @db.shift.last )
                end
            end
        end
    end
    alias :deq :pop
    alias :shift :pop

    # @return   [Integer]
    #   Size of the queue, the number of objects it currently holds.
    def size
        @db.size
    end
    alias :length :size

    # @return   [Bool]
    #   `true` if the queue if empty, `false` otherwise.
    def empty?
        synchronize do
            @db.empty?
        end
    end

    # Removes all objects from the queue.
    def clear
        synchronize do
            @db.clear
        end
    end

    def num_waiting
        @waiting.size
    end

    private

    def synchronize( &block )
        @mutex.synchronize( &block )
    end

end

end
end
