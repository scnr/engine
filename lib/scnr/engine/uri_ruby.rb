=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'uri_common'
require 'ipaddr'

module SCNR::Engine

# The URI class automatically normalizes the URLs it is passed to parse
# while maintaining compatibility with Ruby's URI core class.
#
# It also provides *cached* (to maintain a low latency) helper class methods to
# ease common operations such as:
#
# * {URICommon::ClassMethods.normalize Normalization}.
# * Parsing to {URICommon::ClassMethods.parse SCNR::Engine::URIRuby}
#   (see also {.URI}) or {.fast_parse Hash} objects.
# * Conversion to {URICommon::ClassMethods.to_absolute absolute URLs}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class URIRuby
    include URICommon

    QUERY_CHARACTER_CLASS = Addressable::URI::CharacterClasses::QUERY.sub( '\\&', '' )

    VALID_SCHEMES     = Set.new(%w(http https))
    PARTS             = %w(scheme userinfo host port path query)
    TO_ABSOLUTE_PARTS = %w(scheme userinfo host port)

    class <<self

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
            return if !url || url.empty?
            return if url.start_with?( '#' )

            durl = url.downcase
            return if durl.start_with?( 'javascript:' ) ||
                durl.start_with?( 'data:' )

            # One to rip apart.
            url = url.dup

            # Remove the fragment if there is one.
            url.sub!( /#.*/, '' )

            # One for reference.
            c_url = url

            components = {
                scheme:   nil,
                userinfo: nil,
                host:     nil,
                port:     nil,
                path:     nil,
                query:    nil
            }

            begin
                # Parsing the URL in its schemeless form is trickier, so we
                # fake it, pass a valid scheme to get through the parsing and
                # then remove it at the other end.
                if (schemeless = url.start_with?( '//' ))
                    url.insert 0, 'http:'
                end

                url = Utilities.html_decode( url )

                dupped_url = url.dup
                has_path = true

                splits = url.split( ':' )
                if !splits.empty? && VALID_SCHEMES.include?( splits.first.downcase )

                    splits = url.split( '://', 2 )
                    components[:scheme] = splits.shift
                    components[:scheme].downcase! if components[:scheme]

                    if (url = splits.shift)
                        userinfo_host, url =
                            url.to_s.split( '?' ).first.to_s.split( '/', 2 )

                        url    = url.to_s
                        splits = userinfo_host.to_s.split( '@', 2 )

                        if splits.size > 1
                            components[:userinfo] = splits.first
                        end

                        if !splits.empty?
                            splits = splits.last.split( '/', 2 )

                            splits = splits.first.split( ':', 2 )
                            if splits.size == 2
                                host = splits.first

                                if splits.last && !splits.last.empty?
                                    components[:port] = splits.last.to_i
                                end

                                if components[:port] == 80
                                    components[:port] = nil
                                end
                            else
                                host = splits.last
                            end

                            if (components[:host] = host)
                                components[:host].downcase!
                            end
                        else
                            has_path = false
                        end
                    else
                        has_path = false
                    end
                end

                if has_path
                    splits = url.split( '?', 2 )
                    if (components[:path] = splits.shift)
                        if components[:scheme]
                            components[:path] = "/#{components[:path]}"
                        end

                        components[:path].gsub!( /\/+/, '/' )

                        # Remove path params
                        components[:path].sub!( /\;.*/, '' )

                        if components[:path]
                            components[:path] =
                                encode( decode( components[:path] ),
                                        Addressable::URI::CharacterClasses::PATH ).dup

                            components[:path].gsub!( ';', '%3B' )
                        end
                    end

                    if c_url.include?( '?' ) &&
                        !(query = dupped_url.split( '?', 2 ).last).empty?

                        components[:query] = (query.split( '&', -1 ).map do |pair|
                            encode( decode( pair ), QUERY_CHARACTER_CLASS )
                        end).join( '&' )
                    end
                end

                if schemeless
                    components.delete :scheme
                end

                components[:path] ||= components[:scheme] ? '/' : nil

                components
            rescue => e
                print_debug "Failed to parse '#{c_url}'."
                print_debug "Error: #{e}"
                print_debug_backtrace( e )

                nil
            end
        end

        # @private
        def _decode( string )
            s = Addressable::URI.unencode( string.gsub( '+', '%20' ) )
            s.recode! if s
            s
        end

    end

    # @note Will discard the fragment component, if there is one.
    #
    # @param    [String]    url
    def initialize( url )
        @data = self.class.fast_parse( url )

        fail Error, 'Failed to parse URL.' if !@data

        PARTS.each do |part|
            instance_variable_set( "@#{part}", @data[part.to_sym] )
        end

        reset_userpass
    end

    def ==( other )
        to_s == other.to_s
    end

    def absolute?
        !!@scheme
    end

    def relative?
        !absolute?
    end

    # Converts self into an absolute URL using `reference` to fill in the
    # missing data.
    #
    # @param    [SCNR::Engine::URI, #to_s]    reference
    #   Full, absolute URL.
    #
    # @return   [SCNR::Engine::URI]
    #   Copy of self, as an absolute URL.
    def to_absolute!( reference )
        if !reference.is_a?( self.class )
            reference = self.class.new( reference.to_s )
        end

        TO_ABSOLUTE_PARTS.each do |part|
            next if send( part )

            ref_part = reference.send( "#{part}" )
            next if !ref_part

            send( "#{part}=", ref_part )
        end

        base_path = reference.path.split( %r{/+}, -1 )
        rel_path  = path.to_s.split( %r{/+}, -1 )

        # RFC2396, Section 5.2, 6), a)
        base_path << '' if base_path.last == '..'
        while (i = base_path.index( '..' ))
            base_path.slice!( i - 1, 2 )
        end

        if (first = rel_path.first) && first.empty?
            base_path.clear
            rel_path.shift
        end

        # RFC2396, Section 5.2, 6), c)
        # RFC2396, Section 5.2, 6), d)
        rel_path.push('') if rel_path.last == '.' || rel_path.last == '..'
        rel_path.delete('.')

        # RFC2396, Section 5.2, 6), e)
        tmp = []
        rel_path.each do |x|
            if x == '..' &&
                !(tmp.empty? || tmp.last == '..')
                tmp.pop
            else
                tmp << x
            end
        end

        add_trailer_slash = !tmp.empty?
        if base_path.empty?
            base_path = [''] # keep '/' for root directory
        elsif add_trailer_slash
            base_path.pop
        end

        while (x = tmp.shift)
            if x == '..'
                # RFC2396, Section 4
                # a .. or . in an absolute path has no special meaning
                base_path.pop if base_path.size > 1
            else
                # if x == '..'
                #   valid absolute (but abnormal) path "/../..."
                # else
                #   valid absolute path
                # end
                base_path << x
                tmp.each {|t| base_path << t}
                add_trailer_slash = false
                break
            end
        end

        base_path.push('') if add_trailer_slash
        @path = base_path.join('/')

        self
    end

    # @return   [String]
    #   The URL up to its resource component (query, fragment, etc).
    def without_query
        to_s.split( '?', 2 ).first.to_s
    end

    # @return   [String]
    #   Name of the resource.
    def resource_name
        path.split( '/' ).last
    end

    # @return   [String, nil]
    #   The extension of the URI {#resource_name}, `nil` if there is none.
    def resource_extension
        name = resource_name.to_s
        return if !name.include?( '.' )

        name.split( '.' ).last
    end

    # @return   [String]
    #   The URL up to its path component (no resource name, query, fragment, etc).
    def up_to_path
        return up_to_port if !path

        uri_path = path.dup

        if !uri_path.end_with?( '/' )
            splits  = uri_path.split( '/' )
            splits.pop

            uri_path = splits.join( '/' )
            uri_path << '/'
        end

        up_to_port + uri_path
    end

    # @return   [String]
    #   Scheme, host & port only.
    def up_to_port
        uri_str = "#{scheme}://#{host}"

        if port && (
            (scheme == 'http' && port != 80) ||
                (scheme == 'https' && port != 443)
        )
            uri_str << ':'
            uri_str << port.to_s
        end

        uri_str
    end

    # @return [String]
    #   `domain_name.tld`
    def domain
        return if !host
        return host if ip_address?

        s = host.split( '.' )
        return s.first if s.size == 1
        return host    if s.size == 2

        s[1..-1].join( '.' )
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

    # @return   [Boolean]
    #   `true` if the URI contains an IP address, `false` otherwise.
    def ip_address?
        !(IPAddr.new( host ) rescue nil).nil?
    end

    # @return   [Hash]
    #   Extracted inputs from a URL query.
    def query_parameters
        q = self.query
        return {} if q.to_s.empty?

        q.split( '&' ).inject( {} ) do |h, pair|
            name, value = pair.split( '=', 2 )
            h[self.class.decode( name.to_s )] = self.class.decode( value.to_s )
            h
        end
    end

    def query
        @query
    end

    def query=( q )
        @query = nil_if_empty( q )
    end

    def userinfo=( ui )
        @userinfo = nil_if_empty( ui )
    ensure
        reset_userpass
    end

    def userinfo
        @userinfo
    end

    def user
        @user
    end

    def password
        @password
    end

    def port
        @port
    end

    def port=( p )
        @port = p ? p.to_i : nil
    end

    def host
        @host
    end

    def host=( h )
        @host = nil_if_empty( h )
    end

    def path
        @path
    end

    def path=( p )
        @path = p
    end

    def scheme
        @scheme
    end

    def scheme=( s )
        @scheme = nil_if_empty( s )
    end

    # @return   [String]
    def to_s
        s = ''

        if @scheme
            s << @scheme
            s << '://'
        end

        if @userinfo
            s << @userinfo
            s << '@'
        end

        if @host
            s << @host

            if @port
                if (@scheme == 'http' && @port != 80) ||
                    (@scheme == 'https' && @port != 443)

                    s << ':'
                    s << @port.to_s
                end
            end
        end

        s << @path.to_s

        if @query
            s << '?'
            s << @query
        end

        s
    end

    def dup
        i = self.class.allocate
        instance_variables.each do |iv|
            next if !(v = instance_variable_get( iv ))
            i.instance_variable_set iv, (v.dup rescue v)
        end
        i
    end

    def hash
        to_s.hash
    end

    def persistent_hash
        to_s.persistent_hash
    end

    private

    def nil_if_empty( s )
        return if !s
        s.empty? ? nil : s
    end

    def reset_userpass
        if @userinfo
            @user, @password = @userinfo.split( ':', -1 )
        else
            @user = @password = nil
        end
    end

end
end
