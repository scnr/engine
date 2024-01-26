=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

lib = SCNR::Engine::Options.paths.support + 'cache/'
require lib + 'base'
require lib + 'least_recently_pushed'
require lib + 'least_recently_used'
require lib + 'random_replacement'
require lib + 'least_cost_replacement'
require lib + 'preference'
