require_relative '../../../../lib/scnr/engine'

CURRENT_CHECK = {}

def framework
    SCNR::Engine::Framework.unsafe
end

def current_check
    shortname = File.basename( caller.first.split( ':' ).first, '.rb' )
    CURRENT_CHECK[shortname] ||= framework.checks[shortname]
end

def check_name
    File.basename( caller.first.split( ':' ).first, '.rb' )
end
