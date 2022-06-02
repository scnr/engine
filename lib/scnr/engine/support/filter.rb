=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

lib = SCNR::Engine::Options.paths.support + 'filter/'
require lib + 'base'
require lib + 'set'
require lib + 'bloom'
