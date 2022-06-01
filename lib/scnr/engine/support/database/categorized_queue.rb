=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'gdbm'

module SCNR::Engine
module Support::Database

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class CategorizedQueue < Base

    attr_accessor :prefer

    # @see SCNR::Engine::Database::Base#initialize
    def initialize( options = {}, &block )
        super( options )

        @prefer = block
        @db     = GDBM.new( "#{self.class.disk_directory}/#{object_id}.db" )

        @categories ||= {}
        @waiting      = []
        @mutex        = Mutex.new

        @push_counter = 0
    end

    def categories
        @categories.keys
    end

    # @param    [Object]    obj
    #   Object to add to the queue.
    #   Must respond to #category.
    def <<( obj )
        fail ArgumentError, 'Missing #prefer block.' if !@prefer

        if !obj.respond_to?( :category )
            fail ArgumentError, "#{obj.class} does not respond to #category."
        end

        synchronize do
            k = @push_counter.to_s
            @categories[obj.category] ||= []
            @categories[obj.category] << k

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
        fail ArgumentError, 'Missing #prefer block.' if !@prefer

        synchronize do
            loop do
                if @db.empty?
                    raise ThreadError, 'queue empty' if non_block
                    @waiting.push Thread.current
                    @mutex.sleep
                else
                    # Get preferred category, hopefully there'll be some data
                    # for it.
                    category = @prefer.call( @categories.keys )

                    # Get all other available categories just in case the
                    # preferred one is empty.
                    categories = @categories.keys
                    categories.delete category

                    # Check if our category has data and pick another if not.
                    loop do
                        break if @categories[category]&.any?
                        category = categories.pop
                    end

                    return unserialize( @db.delete( @categories[category].shift ) )
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
            @categories.clear
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
