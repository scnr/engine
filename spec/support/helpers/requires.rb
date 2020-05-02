=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

def require_lib( path )
    require SCNR::Engine::Options.paths.lib + path
end

def require_testee
    require Kernel.caller.first.split( ':' ).first.
                gsub( '/spec/engine', '/lib/scnr/engine' ).gsub( '_spec', '' )
end
