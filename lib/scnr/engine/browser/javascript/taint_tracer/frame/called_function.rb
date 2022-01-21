=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
class Javascript
class TaintTracer
class Frame

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class CalledFunction

    # @return   [String, nil]
    #   Source of the function.
    attr_accessor :source

    # @return   [String]
    #   Name of the function.
    attr_accessor :name

    # @return   [Array]
    #   Arguments passed to the relevant function.
    attr_accessor :arguments

    def initialize( options = {} )
        options.my_symbolize_keys(false).each do |k, v|
            send( "#{k}=", v )
        end
    end

    def signature_arguments
        return if !signature
        signature.match( /\((.*)\)/ )[1].split( ',' ).map(&:strip)
    end

    def signature
        return if !@source
        @source.match( /function\s*(.*?)\s*\{/m )[1]
    end

    def to_h
        instance_variables.inject({}) do |h, iv|
            h[iv.to_s.gsub('@', '').to_sym] = instance_variable_get( iv )
            h
        end
    end
    alias :to_hash :to_h

    def hash
        to_h.hash
    end

    def ==( other )
        hash == other.hash
    end

    def to_rpc_data
        to_h
    end

    def self.from_rpc_data( data )
        new data
    end

end

end

end
end
end
end

