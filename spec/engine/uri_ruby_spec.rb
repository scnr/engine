require 'spec_helper'

require SCNR::Engine::Options.paths.lib + 'uri_ruby'

describe SCNR::Engine::URIRuby do
    it_behaves_like 'uri'
end
