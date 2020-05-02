=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'singleton'
require 'ostruct'

lib = SCNR::Engine::Options.paths.lib
require lib + 'rpc/client/instance'
require lib + 'rpc/client/dispatcher'
require lib + 'rpc/client/queue'

lib = SCNR::Engine::Options.paths.lib + 'processes/'
require lib + 'manager'
require lib + 'dispatchers'
require lib + 'instances'
require lib + 'queues'
