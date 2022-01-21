=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Support

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Glob

    def self.to_regexp( glob )
        escaped = Regexp.escape( glob ).gsub( '\*', '.*?' )
        Regexp.new( "^#{escaped}$", Regexp::IGNORECASE )
    end

    attr_reader :regexp

    def initialize( glob )
        @regexp = self.class.to_regexp( glob )
    end

    def =~( str )
        @regexp.match? str
    end
    alias :matches? :=~
    alias :match? :matches?

end

end
end
