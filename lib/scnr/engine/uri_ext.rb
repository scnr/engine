=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'uri_common'

module SCNR::Engine

# The URI class automatically normalizes the URLs it is passed to parse
# while maintaining compatibility with Ruby's URI core class.
#
# It also provides *cached* (to maintain a low latency) helper class methods to
# ease common operations such as:
#
# * {URICommon::ClassMethods.normalize Normalization}.
# * Parsing to {URICommon::ClassMethods.parse SCNR::Engine::URIExt}
#   (see also {.URI}) or {.fast_parse Hash} objects.
# * Conversion to {URICommon::ClassMethods.to_absolute absolute URLs}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class URIExt < Rust::URI
    include URICommon

    class <<self

        alias :fast_parse_ext :fast_parse
        # Performs a parse that is less resource intensive than Ruby's URI lib's
        # method while normalizing the URL (will also discard the fragment and
        # path parameters).
        #
        # @param    [String]  url
        #
        # @return   [Hash]
        #   URL components (frozen):
        #
        #     * `:scheme` -- HTTP or HTTPS
        #     * `:userinfo` -- `username:password`
        #     * `:host`
        #     * `:port`
        #     * `:path`
        #     * `:query`
        def fast_parse( url )
            if (components = fast_parse_ext( url )).any?
                components
            else
                print_debug "Failed to parse '#{url}'."
                nil
            end
        end

        # @private
        def _decode( string )
            _decode_ext( string ).force_encoding( 'utf-8' )
        end

    end

    alias :to_absolute_ext! :to_absolute!
    def to_absolute!( reference )
        if !reference.is_a?( self.class )
            reference = self.class.new( reference.to_s )
        end

        to_absolute_ext!( reference )
    end

end
end
