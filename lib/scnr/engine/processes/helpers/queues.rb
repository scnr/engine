=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @param (see SCNR::Engine::Processes::Queues#spawn)
# @return (see SCNR::Engine::Processes::Queues#spawn)
def queue_spawn( *args )
    SCNR::Engine::Processes::Queues.spawn( *args )
end

# @param (see SCNR::Engine::Processes::Queues#kill)
# @return (see SCNR::Engine::Processes::Queues#kill)
def queue_kill( *args )
    SCNR::Engine::Processes::Queues.kill( *args )
end

# @param (see SCNR::Engine::Processes::Queues#killall)
# @return (see SCNR::Engine::Processes::Queues#killall)
def queue_killall
    SCNR::Engine::Processes::Queues.killall
end

# @param (see SCNR::Engine::Processes::Queues#connect)
# @return (see SCNR::Engine::Processes::Queues#connect)
def queue_connect( *args )
    SCNR::Engine::Processes::Queues.connect( *args )
end
