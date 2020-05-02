=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class State

class SinkTracer

    # @return   [Support::Hash]
    attr_reader :sinks

    def initialize
        @sinks = Support::Hash.new( :long_to_ruby )

        @mutex = Monitor.new
    end

    def get( element, sink )
        synchronize do
            self.for( element )[sink] ||= Set.new
        end
    end

    def push( element, sink )
        synchronize do
            self.get( element, sink ) << element.affected_input_name
        end
    end

    def include?( element, sink )
        synchronize do
            if element.mutation?
                get( element, sink ).include?( element.affected_input_name )
            else
                get( element, sink ).any?
            end
        end
    end

    def for( element )
        synchronize do
            sinks[element.sink_hash] ||= {}
        end
    end

    def statistics
        {
            sinks_size: @sinks.size
        }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        %w(sinks).each do |attribute|
            IO.binwrite( "#{directory}/#{attribute}", Marshal.dump( send(attribute) ) )
        end
    end

    def self.load( directory )
        sink_tracer = self.new

        %w(sinks).each do |attribute|
            path = "#{directory}/#{attribute}"
            next if !File.exist?( path )

            sink_tracer.send(attribute).merge! Marshal.load( IO.binread( path ) )
        end

        sink_tracer
    end

    def clear
        @sinks.clear
    end

    private

    def synchronize( &block )
        @mutex.synchronize( &block )
    end


end

end
end
