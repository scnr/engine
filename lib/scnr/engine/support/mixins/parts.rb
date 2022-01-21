=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Support
module Mixins

module Parts

    def self.included( base )
        dir = Utilities.caller_path( 3 ).split( '.rb', 2 ).first
        Dir.glob( "#{dir}/parts/**/*.rb" ).each { |f| require f }

        parts = base.const_get( :Parts )
        parts.constants.each do |part_name|
            base.include parts.const_get( part_name )
        end
    end

end
end
end
end
