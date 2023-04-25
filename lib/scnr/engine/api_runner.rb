require_relative 'api'

SCNR::Engine::API.run caller.last.split( ':', 2 ).first

exit
