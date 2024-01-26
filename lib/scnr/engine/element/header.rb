=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require SCNR::Engine::Options.paths.lib + 'element/base'

module SCNR::Engine::Element

# Represents an auditable request header element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Header < Base

    # Load and include all form-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    # Generic element capabilities.
    include SCNR::Engine::Element::Capabilities::WithSinks
    include SCNR::Engine::Element::Capabilities::Auditable
    include SCNR::Engine::Element::Capabilities::Submittable
    include SCNR::Engine::Element::Capabilities::Inputtable
    include SCNR::Engine::Element::Capabilities::Analyzable

    # Header-specific overrides.
    include Capabilities::Mutable
    include Capabilities::Inputtable

    ENCODE_CHARACTERS      = ["\n", "\r"]
    ENCODE_CHARACTERS_LIST = ENCODE_CHARACTERS.join

    ENCODE_CACHE = SCNR::Engine::Support::Cache::LeastRecentlyPushed.new( size: 2_000 )

    def initialize( options )
        super( options )

        self.inputs = options[:inputs]

        @default_inputs = self.inputs.dup.freeze
    end

    def simple
        @inputs.dup
    end

    # @return   [String]
    #   Header name.
    def name
        @inputs.first.first
    end

    # @return   [String]
    #   Header value.
    def value
        @inputs.first.last
    end

    class <<self
        def encode( str )
            return '' if !str

            ENCODE_CACHE.fetch( str ) do
                if SCNR::Engine.has_extension?
                    SCNR::Engine::Rust::Element::Header.encode_ext( str )
                else
                    encode_ruby( str )
                end
            end
        end

        def encode_ruby( str )
            if !ENCODE_CHARACTERS.find { |c| str.include? c }
                str
            else
                ::URI.encode( str, ENCODE_CHARACTERS_LIST )
            end
        end

        def decode( header )
            SCNR::Engine::URI.decode( header.to_s )
        end
    end

    def encode( header )
        self.class.encode( header )
    end

    def decode( header )
        self.class.decode( header )
    end

    private

    def http_request( opts, &block )
        http.header( @action, opts, &block )
    end

end
end

SCNR::Engine::Header = SCNR::Engine::Element::Header
