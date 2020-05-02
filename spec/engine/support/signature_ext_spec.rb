require 'spec_helper'

if !SCNR::Engine.windows?
    require SCNR::Engine::Options.paths.support + 'signature_ext'

    describe SCNR::Engine::Support::SignatureExt do
        it_behaves_like 'signature'
    end
end
