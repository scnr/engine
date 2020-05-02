require 'spec_helper'

describe SCNR::Engine::RPC::Client::Instance do

    let(:subject) { instance_spawn }

    context 'when connecting to an instance' do
        context 'which requires a token' do
            context 'with a valid token' do
                it 'connects successfully' do
                    expect(subject.alive?).to be_truthy
                end
            end

            context 'with an invalid token' do
                it 'should fail to connect' do
                    expect do
                        described_class.new( subject.url, 'blah' ).alive?
                    end.to raise_error Arachni::RPC::Exceptions::InvalidToken
                end
            end
        end
    end

    describe '#options' do
        let(:options) { subject.options }

        describe '#set' do
            let(:url) { SCNR::Engine::Utilities.normalize_url( 'http://test.com' ) + '3' }

            it 'allows batch assigning using a hash' do
                expect(options.set( url: url )).to be_truthy
                expect(options.url).to eq(url)
            end
        end
    end

end
