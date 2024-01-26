=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser::Javascript::Proxy

# Prepares JS calls for the given object based on property type.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Stub

    # @param    [Proxy]    proxy
    #   Parent {Proxy}.
    def initialize( proxy )
        @proxy = proxy
    end

    # @param    [#to_sym] name
    #   Function name.
    # @param    [Array] arguments
    #   Arguments to pass to the JS function.
    #
    # @return   [String]
    #   JS code to call the given function.
    def function( name, *arguments )
        arguments = arguments.map { |arg| arg.to_json }.join( ', ' )

        if name.to_s.end_with?( '=' )
            "#{property( name )}#{arguments if !arguments.empty?}"
        else
            "#{property( name )}(#{arguments if !arguments.empty?})"
        end
    end

    # @param    [#to_sym] name
    #   Function name.
    #
    # @return   [String]
    #   JS code to retrieve the given property.
    def property( name )
        "#{@proxy.js_object}.#{name}"
    end

    # @param    [#to_sym] name
    #   Function/property name.
    # @param    [Array] arguments
    #   Arguments to pass to the JS function.
    #
    # @return   [String]
    #   JS code to call the given function or retrieve the given property.
    #   (Type detection is performed by {Proxy#function?}.)
    def write( name, *arguments )
        @proxy.function?( name ) ?
            function( name, *arguments ) : property( name )
    end

    # @return   [String]
    def to_s
        "<#{self.class}##{object_id} #{@proxy.js_object}>"
    end

end

end
end
