require 'spec_helper'

describe SCNR::Engine::Element::Path do
    it_should_behave_like 'element'
    it_should_behave_like 'with_auditor'

    let( :response ) do
        SCNR::Engine::HTTP::Response.new(
            request: SCNR::Engine::HTTP::Request.new(
                         url:    'http://a-url.com/',
                         method: :get,
                         headers: {
                             'req-header-name' => 'req header value'
                         }
                     ),

            code:    200,
            url:     'http://a-url.com/?myvar=my%20value',
            headers: {}
        )
    end

    subject { described_class.new response.url }

    describe '#action' do
        it 'delegates to #url' do
            expect(subject.action).to eq(subject.url)
        end
    end
end
