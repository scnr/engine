require_relative '../../../../lib/scnr/engine'

CURRENT_CHECK = {}
MUTEX = Mutex.new

def framework
    SCNR::Engine::Framework.unsafe
end

def current_check
    shortname = File.basename( caller.first.split( ':' ).first, '.rb' )
    MUTEX.synchronize do
        CURRENT_CHECK[shortname] ||= framework.checks[shortname]
    end
end

def check_name
    File.basename( caller.first.split( ':' ).first, '.rb' )
end
