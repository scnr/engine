require 'spec_helper'

describe SCNR::Engine::Platform::Fingerprinters::ASPXMVC do
    include_examples 'fingerprinter'

    def platforms
        [:asp, :aspx, :windows, :aspx_mvc]
    end

    context 'when there is a __requestverificationtoken cookie' do
        it 'identifies it as ASP.NET MVC' do
            check_platforms SCNR::Engine::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [SCNR::Engine::Cookie.new(
                              url:    'http://stuff.com/blah',
                              inputs: { '__requestverificationtoken' => 'stuff' } )]

            )
        end
    end

    context 'when there is an X-AspNetMvc-Version header' do
        it 'identifies it as ASP.NET MVC' do
            check_platforms SCNR::Engine::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'X-AspNetMvc-Version' => '2.0' } }
            )
        end
    end

end
