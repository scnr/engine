require 'spec_helper'

describe SCNR::Engine::HTTP::Client::Soft404 do

    before :each do
        described_class::Handler::CACHE.values.each(&:clear)
    end

    subject { client.soft_404 }
    let(:client) { SCNR::Engine::HTTP::Client }
    let(:url) { original_url }
    let(:original_url) { "#{web_server_url_for( :soft_404 )}/" }

    describe '#match?' do
        context 'when not dealing with a redirect' do
            context 'to an outside custom 404' do
                let(:soft_404_redirect_1) { web_server_url_for( :soft_404_redirect_1 ) }
                let(:soft_404_redirect_2) { web_server_url_for( :soft_404_redirect_2 ) }

                it 'returns true' do
                    SCNR::Engine::HTTP::Client.get(
                        "#{soft_404_redirect_1}/set-redirect",
                        parameters: {
                            url: soft_404_redirect_2
                        },
                        mode: :sync
                    )

                    response = client.get(
                        soft_404_redirect_1 + '/test/stuff.php',
                        follow_location: true,
                        mode:            :sync
                    )

                    bool = false
                    subject.match?( response ) { |c_bool| bool = c_bool }
                    client.run

                    expect(bool).to be_truthy
                end
            end
        end

        context 'when not dealing with a not-found response' do
            it 'returns false' do
                res = nil
                client.get( url + 'not' ) { |c_res| res = c_res }
                client.run
                bool = false
                subject.match?( res ) { |c_bool| bool = c_bool }
                client.run
                expect(bool).to be_falsey
            end
        end

        context 'when dealing with a static handler' do
            it 'returns true' do
                res = nil
                client.get( url + 'static/crap' ) { |c_res| res = c_res }
                client.run

                bool = false
                subject.match?( res ) { |c_bool| bool = c_bool }
                client.run
                expect(bool).to be_truthy
            end
        end

        context 'when dealing with a dynamic handler' do
            context 'which at any point returns non-200' do
                it 'aborts the check' do
                    response = client.get( url + 'dynamic/erratic/code/test', mode: :sync )

                    check = nil
                    subject.match?( response ) { |bool| check = bool }
                    client.run

                    expect(check).to be_nil
                end
            end

            context 'which is too erratic' do
                it 'aborts the check' do
                    response = client.get( url + 'dynamic/erratic/body/test', mode: :sync )

                    check = nil
                    subject.match?( response ) { |bool| check = bool }
                    client.run

                    expect(check).to be_nil
                end
            end

            context 'which includes the requested resource in the response' do
                it 'returns true' do
                    res = nil
                    client.get( url + 'dynamic/crap' ) { |c_res| res = c_res }
                    client.run
                    bool = nil
                    subject.match?( res ) { |c_bool| bool = c_bool }
                    client.run
                    expect(bool).to be_truthy
                end
            end

            context 'which includes constantly changing text in the response' do
                it 'returns true' do
                    res = nil
                    client.get( url + 'random/crap' ) { |c_res| res = c_res }
                    client.run
                    bool = nil
                    subject.match?( res ) { |c_bool| bool = c_bool }
                    client.run
                    expect(bool).to be_truthy
                end
            end
            context 'which returns a combination of the above' do
                it 'returns true' do
                    res = nil
                    client.get( url + 'combo/crap' ) { |c_res| res = c_res }
                    client.run
                    bool = nil
                    subject.match?( res ) { |c_bool| bool = c_bool }
                    client.run
                    expect(bool).to be_truthy
                end
            end

            context 'when checking for a resource with a name and extension' do
                context 'and the handler is extension-sensitive' do
                    it 'returns true' do
                        res = nil
                        client.get( url + 'advanced/sensitive-ext/blah.html2' ) { |c_res| res = c_res }
                        client.run

                        bool = nil
                        subject.match?( res ) { |c_bool| bool = c_bool }
                        client.run

                        expect(bool).to be_truthy
                    end
                end
            end

            context 'when checking for a resource with a name that includes ~' do
                context 'and the handler ignores it' do
                    it 'returns true'
                end
            end

            context 'which ignores anything past the resource name' do
                context 'with a non existent resource' do
                    it 'returns true' do
                        res = nil
                        client.get( url + '/ignore-after-filename/123dd/' ) { |c_res| res = c_res }
                        client.run

                        bool = nil
                        subject.match?( res ) { |c_bool| bool = c_bool }
                        client.run

                        expect(bool).to be_truthy
                    end
                end
            end

            context 'which ignores anything ahead of the resource name' do
                context 'with a non existent resource' do
                    it 'returns true' do
                        res = nil
                        client.get( url + '/ignore-before-filename/fff123/' ) { |c_res| res = c_res }
                        client.run

                        bool = nil
                        subject.match?( res ) { |c_bool| bool = c_bool }
                        client.run

                        expect(bool).to be_truthy
                    end
                end
            end

            context 'when checking for a resource with a name that routes based on dash' do
                context 'and the handler is pre-dash sensitive' do
                    context 'and is found' do
                        it 'returns false' do
                            skip

                            res = nil
                            client.get( url + 'advanced/sensitive-dash/pre/blah-html' ) { |c_res| res = c_res }
                            client.run

                            bool = nil
                            subject.match?( res ) { |c_bool| bool = c_bool }
                            client.run

                            expect(bool).to be_falsey
                        end
                    end

                    context 'and is not found' do
                        it 'returns true' do
                            res = nil
                            client.get( url + 'advanced/sensitive-dash/pre/blah2-html' ) { |c_res| res = c_res }
                            client.run

                            bool = nil
                            subject.match?( res ) { |c_bool| bool = c_bool }
                            client.run

                            expect(bool).to be_truthy
                        end
                    end
                end

                context 'and the handler is post-dash sensitive' do
                    context 'and is found' do
                        it 'returns false' do
                            skip

                            res = nil
                            client.get( url + 'advanced/sensitive-dash/post/blah-html' ) { |c_res| res = c_res }
                            client.run

                            bool = nil
                            subject.match?( res ) { |c_bool| bool = c_bool }
                            client.run

                            expect(bool).to be_falsey
                        end
                    end

                    context 'and is not found' do
                        it 'returns true' do
                            res = nil
                            client.get( url + 'advanced/sensitive-dash/post/blah-html2' ) { |c_res| res = c_res }
                            client.run

                            bool = nil
                            subject.match?( res ) { |c_bool| bool = c_bool }
                            client.run

                            expect(bool).to be_truthy
                        end
                    end
                end
            end
        end

        if described_class::CACHE_SIZE > 0
            context 'when checking for an already checked URL' do
                it 'returns the cached result' do
                    res = nil
                    client.get( url + 'static/crap' ) { |c_res| res = c_res }
                    client.run

                    bool = nil
                    subject.match?( res ) { |c_bool| bool = c_bool }
                    client.run
                    expect(bool).to be_truthy

                    fingerprints = 0
                    client.on_complete do
                        fingerprints += 1
                    end

                    res = nil
                    client.get( url + 'static/crap' ) { |c_res| res = c_res }
                    client.run
                    expect(fingerprints).to be > 0

                    overhead = 0
                    client.on_complete do
                        overhead += 1
                    end

                    bool = nil
                    subject.match?( res ) { |c_bool| bool = c_bool }
                    client.run
                    expect(bool).to be_truthy

                    expect(overhead).to eq(0)
                end
            end

            context "when the handler cache exceeds #{described_class::CACHE_SIZE} entries" do
                it 'it is pruned as soon as possible' do
                    expect(subject.handlers).to be_empty

                    client.get( url + 'combo/test' ) do |response|
                        subject.match?(  response ) {}
                    end
                    client.run
                    expect(subject.handlers).to be_any

                    (2 * described_class::CACHE_SIZE).times do |i|
                        url, data = subject.handlers.to_a.first
                        subject.handlers["#{url}/#{i}".hash] = data
                    end
                    client.run

                    expect(subject.handlers.size).to eq(described_class::CACHE_SIZE)
                end
            end
        end
    end

    describe '#hard?' do

        context 'when the page has been fingerprinted' do
            context 'and it has a custom handler' do
                let(:url) { original_url + 'combo/crap' }

                it 'returns false' do
                    client.get( url ) do |response|
                        subject.match?( response ) {}
                    end
                    client.run

                    expect(subject.hard?( url )).to be_falsey
                end
            end

            context 'and it does not have a custom handler' do
                let(:url) { "#{original_url}/blah" }

                it 'returns true' do
                    client.get( url ) do |response|
                        subject.match?( response ) {}
                    end
                    client.run

                    expect(subject.hard?( url )).to be_truthy
                end
            end
        end

        context 'when the page has not been fingerprinted' do
            it 'returns false' do
                expect(subject.hard?( 'path' )).to be_falsey
            end
        end
    end

    describe '.info' do
        it 'returns a hash with an output name' do
            expect(described_class.info[:name]).to eq('Soft404')
        end
    end
end
