require 'spec_helper'

if !SCNR::Engine.windows?
    describe SCNR::Engine::URIExt do
        it_behaves_like 'uri'
    end
end
