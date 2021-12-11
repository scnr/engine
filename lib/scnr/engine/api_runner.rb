require_relative 'api'

SCNR::Engine::API.run caller.first.split( ':', 2 ).first

exit
