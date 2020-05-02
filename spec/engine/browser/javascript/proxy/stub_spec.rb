require 'spec_helper'

describe SCNR::Engine::Browser::Javascript::Proxy::Stub do

    before( :each ) do
        browser.load "#{url}?token=#{javascript.token}"
    end

    subject do
        described_class.new( SCNR::Engine::Browser::Javascript::Proxy.new( javascript, 'ProxyTest' ) )
    end
    let(:url) { SCNR::Engine::Utilities.normalize_url( web_server_url_for( :proxy ) ) }
    let(:proxy) { SCNR::Engine::Browser::Javascript::Proxy.new( javascript, 'ProxyTest' ) }
    let(:javascript) { browser.javascript }
    let(:browser) { SCNR::Engine::Browser.new }
    let(:data) { { 'test' => [1,'2'] } }

    describe '#property' do
        it 'writes property getters' do
            expect(subject.property(:my_property)).to eq("#{proxy.js_object}.my_property")
        end
    end

    describe '#function' do
        it 'writes function calls' do
            expect(subject.function(:my_function, data)).to eq(
                "#{proxy.js_object}.my_function(#{data.to_json})"
            )
        end

        it 'writes property setters' do
            expect(subject.function(:my_property=, 3)).to eq("#{proxy.js_object}.my_property=3")
        end
    end

    describe '#write' do
        it 'writes property getters' do
            expect(subject.write(:my_property)).to eq("#{proxy.js_object}.my_property")
        end

        it 'writes property setters' do
            expect(subject.write(:my_property=, 3)).to eq("#{proxy.js_object}.my_property=3")
        end

        it 'writes function calls' do
            expect(subject.write(:my_function, data)).to eq(
                "#{proxy.js_object}.my_function(#{data.to_json})"
            )
        end

        it 'automatically detects function calls' do
            expect(subject.write(:my_function)).to eq("#{proxy.js_object}.my_function()")
        end
    end
end
