=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Support
end

lib = SCNR::Engine::Options.paths.support
require lib + 'mixins'
require lib + 'buffer'
require lib + 'cache'
require lib + 'crypto'
require lib + 'database'
require lib + 'filter'
require lib + 'glob'
