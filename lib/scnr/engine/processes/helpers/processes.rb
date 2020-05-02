=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @param (see SCNR::Engine::Processes::Manager#kill_reactor)
# @return (see SCNR::Engine::Processes::Manager#kill_reactor)
def process_kill_reactor( *args )
    SCNR::Engine::Processes::Manager.kill_reactor( *args )
end

# @param (see SCNR::Engine::Processes::Manager#kill)
# @return (see SCNR::Engine::Processes::Manager#kill)
def process_kill( *args )
    SCNR::Engine::Processes::Manager.kill( *args )
end

# @param (see SCNR::Engine::Processes::Manager#killall)
# @return (see SCNR::Engine::Processes::Manager#killall)
def process_killall( *args )
    SCNR::Engine::Processes::Manager.killall( *args )
end

# @param (see SCNR::Engine::Processes::Manager#kill_many)
# @return (see SCNR::Engine::Processes::Manager#kill_many)
def process_kill_many( *args )
    SCNR::Engine::Processes::Manager.kill_many( *args )
end
