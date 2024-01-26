=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Support

    Signature = if SCNR::Engine.has_extension?
                    require SCNR::Engine::Options.paths.support + 'signature_ext'
                    SCNR::Engine::Support::SignatureExt
                else
                    require SCNR::Engine::Options.paths.support + 'signature_ruby'
                    SCNR::Engine::Support::SignatureRuby
                end

end
end
