=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'cuboid/processes/helpers'

# Order is important.
INSTANCES = [
    SCNR::Engine::Framework,
    SCNR::Engine::BrowserPool,
    SCNR::Engine::Session,
    SCNR::Engine::Browser,
    SCNR::Engine::Browser::Engines::Base,
    SCNR::Engine::HTTP::Client::Soft404
]
INSTANCES.each(&:_spec_instances_collect!)

def reset_options
    options = SCNR::Engine::Options
    options.reset

    options.paths.plugins        = fixtures_path + 'plugins/'
    options.paths.checks         = fixtures_path + 'checks/'
    options.paths.fingerprinters = fixtures_path + 'fingerprinters/'
    options.paths.logs           = spec_path     + 'support/logs/'
    options.paths.reports        = spec_path     + 'support/reports/'
    options.paths.snapshots      = spec_path     + 'support/snapshots/'
    options.snapshot.path        = options.paths.snapshots

    options.dom.disable!

    options
end

def enable_dom
    SCNR::Engine::Options.dom.pool_size = 1
end

def cleanup_instances
    INSTANCES.each do |i|
        i._spec_instances_cleanup
    end
end

def reset_framework
    SCNR::Engine::UI::OutputInterface.initialize
    # SCNR::Engine::UI::Output.debug_on( 999999 )
    # SCNR::Engine::UI::Output.verbose_on
    # SCNR::Engine::UI::Output.mute

    SCNR::Engine::Framework.reset
    SCNR::Engine::HTTP::Client.reset
end

def reset_all
    reset_options
    reset_framework
end

def processes_killall
    process_killall
    process_kill_reactor
end

def killall
    processes_killall
    web_server_killall
end
