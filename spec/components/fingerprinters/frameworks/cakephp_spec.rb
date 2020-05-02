require 'spec_helper'

describe SCNR::Engine::Platform::Fingerprinters::CakePHP do
    include_examples 'fingerprinter'

    def platforms
        [:php, :cakephp]
    end

    context 'when there is a CAKEPHP cookie' do
        it 'identifies it as CakePHP' do
            check_platforms SCNR::Engine::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [SCNR::Engine::Cookie.new(
                              url: 'http://stuff.com/blah',
                              inputs: { 'CAKEPHP' => 'stuff' } )]

            )
        end
    end

end
