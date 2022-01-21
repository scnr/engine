=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser::Javascript

# Provides a proxy to a Javascript object.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Proxy
    require_relative 'proxy/stub'

    # @return   [Stub]
    #   Stub interface for JS code.
    attr_reader :stub

    # @return   [Javascript]
    #   Active {Javascript} interface.
    attr_reader :javascript

    # @param    [Javascript]    javascript
    #   Active {Javascript} interface.
    # @param    [String]    object
    #   Name of the JS-side object -- will be prefixed with a generated '_token'.
    def initialize( javascript, object )
        @javascript = javascript
        @object     = object
        @stub       = Stub.new( self )
    end

    # @param    [#to_sym] name
    #   Function name to check.
    #
    # @return   [Bool]
    #   `true` if the `name` property of the current object points to a function,
    #   `false` otherwise.
    def function?( name )
        self.class.function?( @javascript, js_object, name )
    end

    # @return   [String]
    #   Active JS-side object name -- prefixed with the relevant `_token`.
    def js_object
        "#{@javascript.token}#{@object}"
    end

    # @param    [Symbol]    function
    #   Javascript property/function.
    # @param    [Array]    arguments
    def call( function, *arguments )
        @javascript.run_without_elements "return #{stub.write( function, *arguments )}"
    end
    alias :method_missing :call

    def self.function?( env, object, name )
        mutex.synchronize do
            @isFunction ||= {}
            key = "#{object}.#{name}".hash

            return @isFunction[key] if @isFunction.include?( key )

            if name.to_s.end_with? '='
                name = name.to_s
                return @isFunction[key] = env.run(
                    "return ('#{name[0...-1]}' in #{object})"
                )
            end

            @isFunction[key] = env.run(
                "return Object.prototype.toString.call( #{object}." <<
                    "#{name} ) == '[object Function]'"
            )
        end
    end
    def self.mutex
        @mutex ||= ::Mutex.new
    end
    mutex

end

end
end
