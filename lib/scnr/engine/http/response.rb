=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module HTTP

# HTTP Response representation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Response < Message
    require_relative 'response/scope'

    HTML_CONTENT_TYPES = Set.new(%w(text/html application/xhtml+xml))

    class Body

        class <<self

            def from( string )
                return string if string.is_a? self

                body = new( string.size )
                body << string
                body
            end

        end

        def initialize( capacity )
            @buffer = String.new( '', capacity: capacity )
        end

        def binary?
            fail_if_freed
            @buffer.binary?
        end

        def html?
            fail_if_freed
            as_document.traverse do |n|
                return true if n.is_a? Parser::Nodes::Element
            end
        end

        def <<( string )
            fail_if_freed
            @buffer << string
        end

        def insert( *args )
            fail_if_freed
            @buffer.insert *args
        end

        def match?( regex )
            fail_if_freed
            regex.match? @buffer
        end

        def match( regex )
            fail_if_freed
            regex.match @buffer
        end

        def include?( substring )
            fail_if_freed
            @buffer.include? substring
        end

        def persistent_hash
            fail_if_freed
            @buffer.persistent_hash
        end

        def hash
            @buffer.hash
        end

        def optimized_include?( substring )
            fail_if_freed
            @buffer.optimized_include? substring
        end

        def gsub( *args )
            fail_if_freed
            self.class.from @buffer.gsub( *args )
        end

        def gsub!( *args )
            fail_if_freed
            @buffer.gsub! *args
            self
        end

        def scan( *args )
            fail_if_freed
            @buffer.scan *args
        end

        def bytesize
            fail_if_freed
            @buffer.bytesize
        end

        def size
            fail_if_freed
            @buffer.size
        end

        def as_document
            fail_if_freed
            Parser.parse @buffer, filter: true
        end

        def diff_ratio( other )
            fail_if_freed
            @buffer.diff_ratio( other.to_string_io.string )
        end

        def signature
            fail_if_freed
            @buffer.signature
        end

        def downcase
            fail_if_freed
            self.class.from @buffer.downcase
        end

        def has_html_tag?( *args )
            fail_if_freed
            @buffer.has_html_tag?( *args )
        end

        def strip
            fail_if_freed
            self.class.from @buffer.strip
        end

        def empty?
            fail_if_freed
            @buffer.empty?
        end

        def free
            fail_if_freed
            @buffer.clear
            @buffer = nil
            @freed = true
            nil
        end

        def to_string_io
            StringIO.new( @buffer )
        end

        def method_missing( *args )
            ap args
            ap caller
            Process.kill 'KILL', Process.pid
        end

        private

        def fail_if_freed
            fail 'Already freed' if @freed
        end
    end

    # @return   [Integer]
    #   HTTP response status code.
    attr_accessor :code

    # @return   [String]
    #   IP address of the server.
    attr_accessor :ip_address

    # @return   [String]
    #   HTTP response status message.
    attr_accessor :message

    # @return   [Request]
    #   HTTP {Request} which triggered this {Response}.
    attr_accessor :request

    # @return   [Array<Response>]
    #   Automatically followed redirections that eventually led to this response.
    attr_accessor :redirections

    # @return   [Symbol]
    #   `libcurl` return code.
    attr_accessor :return_code

    # @return   [String]
    #   `libcurl` return code.
    attr_accessor :return_message

    # @return   [String]
    #   Raw headers.
    attr_accessor :headers_string

    # @return   [Float]
    #   Total time in seconds for the transfer, including name resolving, TCP
    #   connect etc.
    attr_accessor :total_time

    # @return   [Float]
    #   Time, in seconds, it took from the start until the full response was
    #   received.
    attr_accessor :time

    # @return   [Float]
    #   Approximate time the web application took to process the {#request}.
    attr_accessor :app_time

    attr_accessor :status_line

    def initialize( options = {} )
        super( options )

        @body ||= Body.new(0)
        @code ||= 0

        # Holds the redirection responses that eventually led to this one.
        @redirections ||= []

        @time ||= 0.0
    end

    def time=( t )
        @time = t.to_f
    end

    # @return   [Boolean]
    #   `true` if the client could not read the entire response, `false` otherwise.
    def partial?
        # Streamed response which was aborted before completing.
        return_code == :partial_file ||
            return_code == :recv_error ||
            # Normal response with some data written, but without reaching
            # content-length.
            (code != 0 && timed_out?)
    end

    # @return   [Platform]
    #   Applicable platforms for the page.
    def platforms
        Platform::Manager[url]
    end

    # @return   [String]
    #   First line of the response.
    def status_line
        return if !headers_string
        @status_line ||= headers_string.lines.first.to_s.chomp.freeze
    end

    # @return   [String]
    #   HTTP response string.
    def to_s
        "#{headers_string}#{body}"
    end

    # @return [Boolean]
    #   `true` if the response is a `3xx` redirect **and** there is a `Location`
    #   header field.
    def redirect?
        code >= 300 && code <= 399 && !!headers.location
    end
    alias :redirection? :redirect?

    def headers_string=( string )
        @headers_string = string.recode_and_freeze if string
    end

    # @note Depends on the response code.
    #
    # @return [Boolean]
    #   `true` if the remote resource has been modified since the date given in
    #   the `If-Modified-Since` request header field, `false` otherwise.
    def modified?
        code != 304
    end

    # @return [Boolean]
    #   `true` if the request was performed successfully and the response was
    #   received in full, `false` otherwise.
    def ok?
        !return_code || return_code == :ok
    end

    # @return [Bool]
    #   `true` if the response body is textual in nature, `false` if binary,
    #   `nil` if could not be determined.
    def text?
        return nil      if !@body
        return nil      if @is_text == :inconclusive
        return @is_text if !@is_text.nil?

        if (type = headers.content_type)
            return @is_text = true if type.start_with?( 'text/' )

            # Non "text/" nor "application/" content types will surely not be
            # text-based so bail out early.
            return @is_text = false if !type.start_with?( 'application/' )
        end

        # Last resort, more resource intensive binary detection.
        begin
            @is_text = !@body.binary?
        rescue ArgumentError
            @is_text = :inconclusive
            nil
        end
    end

    # @return   [Boolean]
    #   `true` if timed out, `false` otherwise.
    def timed_out?
        return_code == :operation_timedout
    end

    def html?
        # If the server says it's HTML dig deeper to ensure it.
        # We don't want wrong response headers messing up the JS env.
        HTML_CONTENT_TYPES.include?( headers.simple_content_type ) && @body.html?
    end

    def javascript?
        sct = headers.simple_content_type
        return if !sct

        sct.optimized_include? 'javascript'
    end

    def body=( body )
        if body.is_a? Body
            return @body = body
        end

        body = body || ''

        text_check = text?
        body.recode! if text_check.nil? || text_check

        @body = Body.from( body )
    end

    # @return [SCNR::Engine::Page]
    def to_page
        Page.from_response self
    end

    def parse
        Parser.new self
    end

    # @return   [Hash]
    def to_h
        hash = {}
        instance_variables.each do |var|
            hash[var.to_s.gsub( /@/, '' ).to_sym] = instance_variable_get( var )
        end

        hash[:headers] = {}.merge( hash[:headers] )

        hash[:body] = hash[:body].to_string_io.string

        hash.delete( :normalize_url )
        hash.delete( :is_text )
        hash.delete( :scope )
        hash.delete( :parsed_url )
        hash.delete( :redirections )
        hash.delete( :request )
        hash.delete( :scope )

        hash
    end

    def dup
        self.class.from_rpc_data( to_rpc_data.deep_clone )
    end

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        data = to_h
        data[:request] = request.to_rpc_data
        data.my_stringify_keys(false)
    end

    # @param    [Hash]  data    {#to_rpc_data}
    # @return   [Request]
    def self.from_rpc_data( data )
        data['request'] = Request.from_rpc_data( data['request'] )

        if data['return_code'].is_a? String
            data['return_code'] = data['return_code'].to_sym
        end

        new data
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        to_h.hash
    end

    def update_from_typhoeus( response, options = {} )
        return_code    = response.return_code
        return_message = response.return_message

        # A write error in this case will be because body reading was aborted
        # during our own callback in Request#set_body_reader.
        #
        # So, this is here just for consistency.
        if response.return_code == :write_error
            return_code    = :filesize_exceeded
            return_message = 'Maximum file size exceeded'
        end

        update( options.merge(
            url:            response.effective_url,
            code:           response.code,
            ip_address:     response.primary_ip,
            headers:        response.headers,
            headers_string: response.response_headers,
            body:           response.body,
            redirections:   redirections,
            time:           response.time,
            app_time:       (response.timed_out? ? response.time :
                response.start_transfer_time - response.pretransfer_time).to_f,
            total_time:     response.total_time.to_f,
            return_code:    return_code,
            return_message: return_message
        ))
    end

    def self.from_typhoeus( response, options = {} )
        redirections = response.redirections.map do |redirect|
            rurl   = URI.to_absolute( redirect.headers['Location'],
                                      response.effective_url )
            rurl ||= response.effective_url

            # Broken redirection, skip it...
            next if !rurl

            new( options.merge(
                url:           rurl,
                code:          redirect.code,
                headers:       redirect.headers
            ))
        end

        return_code    = response.return_code
        return_message = response.return_message

        # A write error in this case will be because body reading was aborted
        # during our own callback in Request#set_body_reader.
        #
        # So, this is here just for consistency.
        if response.return_code == :write_error
            return_code    = :filesize_exceeded
            return_message = 'Maximum file size exceeded'
        end

        new( options.merge(
            url:            response.effective_url,
            code:           response.code,
            ip_address:     response.primary_ip,
            headers:        response.headers,
            headers_string: response.response_headers,
            body:           response.body,
            redirections:   redirections,
            time:           response.time,
            app_time:       (response.timed_out? ? response.time :
                                response.start_transfer_time - response.pretransfer_time).to_f,
            total_time:     response.total_time.to_f,
            return_code:    return_code,
            return_message: return_message
        ))
    end

end
end
end
