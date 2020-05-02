=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @param (see SCNR::Engine::Processes::Dispatchers#spawn)
# @return (see SCNR::Engine::Processes::Dispatchers#spawn)
def dispatcher_spawn( *args )
    SCNR::Engine::Processes::Dispatchers.spawn( *args )
end

# @param (see SCNR::Engine::Processes::Dispatchers#kill)
# @return (see SCNR::Engine::Processes::Dispatchers#kill)
def dispatcher_kill( *args )
    SCNR::Engine::Processes::Dispatchers.kill( *args )
end

# @param (see SCNR::Engine::Processes::Dispatchers#killall)
# @return (see SCNR::Engine::Processes::Dispatchers#killall)
def dispatcher_killall
    SCNR::Engine::Processes::Dispatchers.killall
end

# @param (see SCNR::Engine::Processes::Dispatchers#connect)
# @return (see SCNR::Engine::Processes::Dispatchers#connect)
def dispatcher_connect( *args )
    SCNR::Engine::Processes::Dispatchers.connect( *args )
end
