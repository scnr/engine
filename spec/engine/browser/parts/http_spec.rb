require 'spec_helper'

describe SCNR::Engine::Browser::Parts::HTTP do
    include_examples 'browser'

    describe '#initialize' do
        describe ':concurrency' do
            it 'sets the HTTP request concurrency'
        end
    end

    describe '#goto' do
        before do
            subject.goto url
        end

        it 'does not receive a Content-Security-Policy header' do
            subject.goto "#{url}/Content-Security-Policy"
            expect(subject.response.code).to eq(200)
            expect(subject.response.headers).not_to include 'Content-Security-Policy'
        end
    end

    describe '#on_response' do
        context 'when a response is preloaded' do
            it 'is passed each response' do
                responses = []
                subject.on_response { |response| responses << response }

                subject.preload SCNR::Engine::HTTP::Client.get( url, mode: :sync )
                subject.goto url

                response = responses.first
                expect(response).to be_kind_of SCNR::Engine::HTTP::Response
                expect(response.url).to eq(url)
            end
        end

        context 'when a request is performed by the browser' do
            it 'is passed each response' do
                responses = []
                subject.on_response { |response| responses << response }

                subject.goto url

                response = responses.first
                expect(response).to be_kind_of SCNR::Engine::HTTP::Response
                expect(response.url).to eq(url)
            end
        end
    end

    describe '#response' do
        it "returns the #{SCNR::Engine::HTTP::Response} for the loaded page" do
            subject.load url

            browser_response = subject.response
            browser_request  = browser_response.request
            raw_response     = SCNR::Engine::HTTP::Client.get( url, mode: :sync )
            raw_request      = raw_response.request

            expect(browser_response.url).to eq(raw_response.url)

            [:url, :method].each do |attribute|
                expect(browser_request.send(attribute)).to eq(raw_request.send(attribute))
            end
        end

        context "when the response takes more than #{SCNR::Engine::OptionGroups::HTTP}#request_timeout" do
            it 'returns nil'
        end

        context 'when the resource is out of scope' do
            it 'returns nil' do
                SCNR::Engine::Options.url = url
                subject.load url

                subject.javascript.run( 'window.location = "http://google.com/";' )
                sleep 1

                expect(subject.response).to be_nil
            end
        end
    end

end
