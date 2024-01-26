=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'addressable/uri'
require_relative 'uri_common/scope'

module SCNR::Engine

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module URICommon
    include UI::Output

    # {URI} error namespace.
    #
    # All {URI} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < SCNR::Engine::Error
    end

    CACHE = {
        parse:       1_000,

        normalize:   1_000,
        to_absolute: 1_000,

        encode:      5_000,
        decode:      5_000
    }.inject({}) do |h, (name, size)|
        h.merge! name => Support::Cache::LeastRecentlyPushed.new( size: size )
    end

    def self.included( base )
        base.extend( ClassMethods )
    end

    module ClassMethods
        include UI::Output

        # URL decodes a string.
        #
        # @param [String] string
        #
        # @return   [String]
        def decode( string )
            return '' if !string

            CACHE[__method__].fetch( string ) do
                _decode string
            end
        end

        # URL encodes a string.
        #
        # @param [String] string
        # @param [String, Regexp] good_characters
        #   Class of characters to allow -- if {String} is passed, it should
        #   formatted as a regexp (for `Regexp.new`).
        #
        # @return   [String]
        #   Encoded string.
        def encode( string, good_characters = nil )
            CACHE[__method__].fetch [string, good_characters] do
                s = Addressable::URI.encode_component(
                    *[string, good_characters].compact
                )
                s.recode!
                s.gsub!( '+', '%2B' )
                s
            end
        end

        # @note This method's results are cached for performance reasons.
        #   If you plan on doing something destructive with its return value
        #   duplicate it first because there may be references to it elsewhere.
        #
        # Cached version of {URI#initialize}, if there's a chance that the same
        # URL will be needed to be parsed multiple times you should use this method.
        #
        # @see URI#initialize
        def parse( url )
            return url if !url || url.is_a?( self )

            CACHE[__method__].fetch url do
                begin
                    url = new( url )
                    raise if url.to_s.empty?
                    url
                rescue => e
                    print_debug "Failed to parse '#{url}'."
                    print_debug "Error: #{e}"
                    print_debug_backtrace( e )
                    nil
                end
            end
        end

        # @note This method's results are cached for performance reasons.
        #   If you plan on doing something destructive with its return value
        #   duplicate it first because there may be references to it elsewhere.
        #
        # {.normalize Normalizes} and converts a `relative` URL to an absolute
        # one by merging in with a `reference` URL.
        #
        # Pretty much a cached version of {#to_absolute}.
        #
        # @param    [String]    relative
        # @param    [String]    reference
        #   Absolute url to use as a reference.
        #
        # @return   [String]
        #   Absolute URL (frozen).
        def to_absolute( relative, reference = Options.instance.url.to_s )
            return normalize( reference ) if !relative || relative.empty?
            key = [relative, reference].hash

            cache = CACHE[__method__]
            begin
                if (v = cache[key]) && v == :err
                    return
                elsif v
                    return v
                end

                parsed_ref = parse( reference )

                if relative.start_with?( '//' )
                    # Scheme-less URLs are expensive to parse so let's resolve
                    # the issue here.
                    relative = "#{parsed_ref.scheme}:#{relative}"
                end

                parsed = parse( relative )

                # Doesn't contain anything or interest (javascript: or fragment only),
                # return the ref.
                return parsed_ref.to_s if !parsed

                cache[key] = parsed.to_absolute( parsed_ref ).to_s
            rescue => e
                cache[key] = :err
                nil
            end
        end

        # @note This method's results are cached for performance reasons.
        #   If you plan on doing something destructive with its return value
        #   duplicate it first because there may be references to it elsewhere.
        #
        # Uses {.parse} to parse and normalize the URL and then converts it to
        # a common {String} format.
        #
        # @param    [String]    url
        #
        # @return   [String]
        #   Normalized URL (frozen).
        def normalize( url )
            return if !url || url.empty?

            cache = CACHE[__method__]

            begin
                if (v = cache[url]) && v == :err
                    return
                elsif v
                    return v
                end

                cache[url] = parse( url ).to_s
            rescue => e
                print_debug "Failed to normalize '#{url}'."
                print_debug "Error: #{e}"
                print_debug_backtrace( e )

                cache[url] = :err
                nil
            end
        end

        # @param    [String]    url
        # @param    [Hash<Regexp => String>]    rules
        #   Regular expression and substitution pairs.
        #
        # @return  [String]
        #   Rewritten URL.
        def rewrite( url, rules = SCNR::Engine::Options.scope.url_rewrites )
            parse( url ).rewrite( rules ).to_s
        end

        # Extracts inputs from a URL query.
        #
        # @param    [String]    url
        #
        # @return   [Hash]
        def parse_query( url )
            parsed = parse( url )
            return {} if !parsed

            parse( url ).query_parameters
        end

        # @param    [String]    url
        #   URL to check.
        #
        # @return   [Bool]
        #   `true` is the URL is full and absolute, `false` otherwise.
        def full_and_absolute?( url )
            return false if !url || url.empty?

            parsed = parse( url )
            return false if !parsed

            parsed.absolute?
        end

        def _load( url )
            new url
        end
    end

    # @return   [Scope]
    def scope
        # We could have several identical URLs in play at any given time and
        # they will all have the same scope.
        URICommon::Scope.new( self )
    end

    # @return   [Bool]
    #   `true` if the scan #{Utilities.random_seed seed} is included in the
    #   domain, `false` otherwise.
    def seed_in_host?
        host && host.optimized_include?( Utilities.random_seed )
    end

    def to_absolute( reference )
        dup.to_absolute!( reference )
    end

    # @param    [Hash<Regexp => String>]    rules
    #   Regular expression and substitution pairs.
    #
    # @return  [URI]
    #   Rewritten URL.
    def rewrite( rules = SCNR::Engine::Options.scope.url_rewrites )
        as_string = self.to_s

        rules.each do |args|
            if (rewritten = as_string.gsub( *args )) != as_string
                return self.class.parse( rewritten )
            end
        end

        self.dup
    end

    def _dump( _ )
        to_s
    end

end

end
