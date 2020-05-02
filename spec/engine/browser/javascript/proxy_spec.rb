require 'spec_helper'

describe SCNR::Engine::Browser::Javascript::Proxy do

    before( :each ) do
        browser.load "#{url}?token=#{javascript.token}"
    end

    subject { described_class.new( javascript, 'ProxyTest' ) }
    let(:url) { SCNR::Engine::Utilities.normalize_url( web_server_url_for( :proxy ) ) }
    let(:browser) { SCNR::Engine::Browser.new }
    let(:javascript) { browser.javascript }
    let(:data) { { 'test' => [1,'2'] } }

    it 'accesses properties' do
        expect(subject.my_property).to be_nil
    end

    it 'sets properties' do
        subject.my_property = data
        expect(subject.my_property).to eq(data)
    end

    it 'calls functions' do
        expect(subject.my_function).to eq([nil, nil, nil])
        expect(subject.my_function( 1, '2', data )).to eq([1, '2', data])
    end

    describe '#stub' do
        it 'returns the Stub instance' do
            expect(subject.stub.to_s).to end_with 'ProxyTest>'
        end
    end

    describe '#javascript' do
        it 'returns the Javascript instance' do
            expect(subject.javascript).to be_kind_of SCNR::Engine::Browser::Javascript
        end
    end

    describe '#js_object' do
        it 'returns the JS-side object of the proxied object' do
            skip

            expect(subject.js_object).to eq("#{javascript.token}ProxyTest")

            js_object = javascript.run( "return #{subject.js_object}" )
            expect(js_object).to include 'my_property'
            expect(js_object['my_function']).to start_with 'function ('
        end
    end

    describe '#function?' do
        context 'when dealing with setters' do
            context 'for existing properties' do
                it 'returns true' do
                    expect(subject.function?( :my_function= )).to be_truthy
                    expect(subject.function?( :my_property= )).to be_truthy
                end
            end

            context 'for nonexistent properties' do
                it 'returns false' do
                    expect(subject.function?( :stuff= )).to be_falsey
                end
            end
        end

        context 'when the specified property is a function' do
            it 'returns true' do
                expect(subject.function?( :my_function )).to be_truthy
            end
        end

        context 'when the specified property is not a function' do
            it 'returns false' do
                expect(subject.function?( :my_property )).to be_falsey
            end
        end
    end

    describe '#call' do
        it 'accesses properties' do
            expect(subject.call(:my_property)).to be_nil
        end

        it 'sets properties' do
            subject.call(:my_property=, data)
            expect(subject.call(:my_property)).to eq(data)
        end

        it 'calls functions' do
            expect(subject.call(:my_function)).to eq([nil, nil, nil])
            expect(subject.call(:my_function, 1, '2', data )).to eq([1, '2', data])
        end
    end
end
