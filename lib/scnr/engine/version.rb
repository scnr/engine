=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR
module Engine

    # the universal system version
    VERSION = IO.read( File.dirname( __FILE__ ) + '/../version' ).strip

end
end
