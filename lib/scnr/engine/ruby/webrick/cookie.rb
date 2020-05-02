=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class WEBrick::Cookie
    attr_accessor :httponly

    class << self
        alias :old_parse_set_cookie :parse_set_cookie
    end

    def self.parse_set_cookie( str )
        cookie = old_parse_set_cookie( str )
        cookie.httponly = str.split( ';' ).map { |f| f.downcase.strip }.
            include?( 'httponly' )
        cookie
    end
end
