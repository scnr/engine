=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class State

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class HTTP

    # @return   [Hash]
    #   HTTP headers for the {SCNR::Engine::HTTP::Client#headers}.
    attr_reader :headers

    # @return   [CookieJar]
    #   Cookie-jar for {SCNR::Engine::HTTP::Client#cookie_jar}.
    attr_reader :cookie_jar

    def initialize
        @headers    = SCNR::Engine::HTTP::Headers.new
        @cookie_jar = SCNR::Engine::HTTP::CookieJar.new
    end

    def statistics
        {
            cookies: @cookie_jar.cookies.map(&:to_s).uniq
        }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        %w(headers cookie_jar).each do |attribute|
            IO.binwrite( "#{directory}/#{attribute}", Marshal.dump( send(attribute) ) )
        end
    end

    def self.load( directory )
        http = new

        %w(headers cookie_jar).each do |attribute|
            http.send(attribute).merge! Marshal.load( IO.binread( "#{directory}/#{attribute}" ) )
        end

        http
    end

    def clear
        @cookie_jar.clear
        @headers.clear
    end

end
end
end

