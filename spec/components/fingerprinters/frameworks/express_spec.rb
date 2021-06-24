require 'spec_helper'

describe SCNR::Engine::Platform::Fingerprinters::Express do
    include_examples 'fingerprinter'

    def platforms
        [:javascript, :express, :nodejs]
    end

    context 'when there is a Server header' do
        it 'identifies it as Express' do
            check_platforms SCNR::Engine::Page.from_data(
              url: 'http://stuff.com/blah',
              response: { headers: { 'Server' => 'Express' } }
            )
        end
    end

    context 'when there is an X-Powered-By header' do
        it 'identifies it as Express' do
            check_platforms SCNR::Engine::Page.from_data(
              url: 'http://stuff.com/blah',
              response: { headers: { 'X-Powered-By' => 'Express' } }
            )
        end
    end

end
