=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @param (see SCNR::Engine::Processes::Instances#spawn)
# @return (see SCNR::Engine::Processes::Instances#spawn)
def instance_spawn( *args )
    SCNR::Engine::Processes::Instances.spawn( *args )
end

# @param (see SCNR::Engine::Processes::Instances#grid_spawn)
# @return (see SCNR::Engine::Processes::Instances#grid_spawn)
def instance_grid_spawn( *args )
    SCNR::Engine::Processes::Instances.grid_spawn( *args )
end

# @param (see SCNR::Engine::Processes::Instances#dispatcher_spawn)
# @return (see SCNR::Engine::Processes::Instances#dispatcher_spawn)
def instance_dispatcher_spawn( *args )
    SCNR::Engine::Processes::Instances.dispatcher.spawn( *args )
end

def instance_kill( url )
    SCNR::Engine::Processes::Instances.kill url
end

# @param (see SCNR::Engine::Processes::Instances#killall)
# @return (see SCNR::Engine::Processes::Instances#killall)
def instance_killall
    SCNR::Engine::Processes::Instances.killall
end

# @param (see SCNR::Engine::Processes::Instances#connect)
# @return (see SCNR::Engine::Processes::Instances#connect)
def instance_connect( *args )
    SCNR::Engine::Processes::Instances.connect( *args )
end

# @param (see SCNR::Engine::Processes::Instances#token_for)
# @return (see SCNR::Engine::Processes::Instances#token_for)
def instance_token_for( *args )
    SCNR::Engine::Processes::Instances.token_for( *args )
end
