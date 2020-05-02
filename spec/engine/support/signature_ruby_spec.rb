require 'spec_helper'
require SCNR::Engine::Options.paths.support + 'signature_ruby'

describe SCNR::Engine::Support::SignatureRuby do
    it_behaves_like 'signature'
end
