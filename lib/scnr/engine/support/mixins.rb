=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Mixins
end

lib = SCNR::Engine::Options.paths.mixins
require lib + 'observable'
require lib + 'decisions'
require lib + 'terminal'
require lib + 'profiler'
require lib + 'parts'
