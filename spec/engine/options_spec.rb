require 'spec_helper'

describe SCNR::Engine::Options do

    subject { described_class.instance }
    groups = described_class.group_classes.keys

    it 'proxies missing class methods to instance methods' do
        url = 'http://test.com/'
        expect(subject.url).not_to eq(url)
        subject.url = url
        expect(subject.url).to eq(url)
    end

    %w(checks platforms plugins authorized_by no_fingerprinting).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    groups.each do |group|
        describe "##{group}" do
            it 'is an OptionGroup' do
                expect(subject.send( group )).to be_kind_of SCNR::Engine::OptionGroup
                expect(subject.send( group ).class.to_s.downcase).to eq(
                    "scnr::engine::optiongroups::#{group}".gsub( '_', '' )
                )
            end
        end
    end

    describe '#do_not_fingerprint' do
        it 'disables fingerprinting' do
            expect(subject.no_fingerprinting).to be_falsey
            subject.do_not_fingerprint
            expect(subject.no_fingerprinting).to be_truthy
        end
    end

    describe '#fingerprint' do
        it 'enables fingerprinting' do
            subject.do_not_fingerprint
            expect(subject.no_fingerprinting).to be_truthy

            subject.fingerprint
            expect(subject.no_fingerprinting).to be_falsey
        end
    end

    describe '#fingerprint?' do
        context 'when fingerprinting is enabled' do
            it 'returns true' do
                subject.no_fingerprinting = false
                expect(subject.fingerprint?).to be_truthy
            end
        end

        context 'when fingerprinting is disabled' do
            it 'returns false' do
                subject.no_fingerprinting = true
                expect(subject.fingerprint?).to be_falsey
            end
        end
    end

    describe '#validate' do
        context 'when valid' do
            it 'returns nil' do
                expect(subject.validate).to be_empty
            end
        end

        context 'when invalid' do
            it 'returns errors by group' do
                subject.session.check_pattern = /test/
                expect(subject.validate).to eq({
                    session: {
                        check_url: "Option is missing."
                    }
                })
            end
        end
    end

    describe '#parsed_url' do
        it 'returns a parsed version of #url' do
            subject.url = 'http://test.com/'
            expect(subject.parsed_url).to eq SCNR::Engine::URI( subject.url )
        end
    end

    describe '#url=' do
        it 'normalizes its argument' do
            subject.url = 'http://test.com/my path'
            expect(subject.url).to eq(SCNR::Engine::Utilities.normalize_url( subject.url ))
        end

        it 'accepts the HTTP scheme' do
            subject.url = 'http://test.com'
            expect(subject.url).to eq('http://test.com/')
        end

        it 'accepts the HTTPS scheme' do
            subject.url = 'https://test.com'
            expect(subject.url).to eq('https://test.com/')
        end

        context 'when nil is passed' do
            it "raises #{described_class::Error::InvalidURL}" do
                expect { subject.url = '/my path' }.to raise_error
                    described_class::Error::InvalidURL
            end
        end

        context 'when a relative URL is passed' do
            it "raises #{described_class::Error::InvalidURL}" do
                expect { subject.url = '/my path' }.to raise_error
                    described_class::Error::InvalidURL
            end
        end

        context 'when a URL with invalid scheme is passed' do
            it "raises #{described_class::Error::InvalidURL}" do
                expect { subject.url = 'httpss://test.com/my path' }.to raise_error
                    described_class::Error::InvalidURL
            end
        end

        context 'when a URL with no scheme is passed' do
            it "raises #{described_class::Error::InvalidURL}" do
                expect { subject.url = 'test.com/my path' }.to raise_error
                    described_class::Error::InvalidURL
            end
        end

        context "when #{SCNR::Engine::OptionGroups::Scope}#https_only?" do
            before :each do
                subject.scope.https_only = true
            end

            context 'and an HTTPS url is provided' do
                it 'accepts the HTTPS scheme' do
                    subject.url = 'https://test.com'
                    expect(subject.url).to eq('https://test.com/')
                end
            end

            context 'and an HTTP url is provided' do
                it "raises #{described_class::Error::InvalidURL}" do
                    expect do
                        subject.url = 'http://test.com/'
                    end.to raise_error described_class::Error::InvalidURL
                end
            end
        end
    end

    describe '#update' do
        it 'sets options by hash' do
            opts = { url: 'http://blah2.com' }

            subject.update( opts )
            expect(subject.url.to_s).to eq(SCNR::Engine::Utilities.normalize_url( opts[:url] ))
        end

        context 'when key refers to an OptionGroup' do
            it 'updates that group' do
                opts = {
                    scope: {
                        exclude_path_patterns:   [ 'exclude me2' ],
                        include_path_patterns:   [ 'include me2' ],
                        redundant_path_patterns: { 'redundant' => 4 }
                    },
                    datastore: {
                        key2: 'val2'
                    }
                }

                subject.update( opts )

                expect(subject.scope.exclude_path_patterns).to eq([/exclude me2/i])
                expect(subject.scope.include_path_patterns).to eq([/include me2/i])
                expect(subject.scope.redundant_path_patterns).to eq({ /redundant/i => 4 })
                expect(subject.datastore.to_h).to eq(opts[:datastore])
            end
        end
    end

    describe '#save' do
        it 'dumps #to_h to a file' do
            f = 'options'

            subject.save( f )

            raised = false
            begin
                File.delete( f )
            rescue
                raised = true
            end
            expect(raised).to be_falsey
        end

        it 'returns the file location'do
            f = 'options'

            f = subject.save( f )

            raised = false
            begin
                File.delete( f )
            rescue
                raised = true
            end
            expect(raised).to be_falsey
        end
    end

    describe '#load' do
        it 'loads a file created by #save' do
            f = "#{Dir.tmpdir}/options"

            subject.scope.restrict_paths = 'test'
            subject.save( f )

            options = subject.load( f )
            expect(options).to eq(subject)
            expect(options.scope.restrict_paths).to eq(['test'])

            raised = false
            begin
                File.delete( f )
            rescue
                raised = true
            end
            expect(raised).to be_falsey
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it 'converts self to a serializable hash' do
            expect(data).to be_kind_of Hash

            expect(SCNR::Engine::RPC::Serializer.load(
                SCNR::Engine::RPC::Serializer.dump( data )
            )).to eq(data)
        end

        (groups - described_class::TO_RPC_IGNORE.to_a).each do |k|
            k = k.to_s

            it "includes the '#{k}' group" do
                expect(data[k]).to eq(subject.send(k).to_rpc_data)
            end
        end

        described_class::TO_RPC_IGNORE.each do |k|
            k = k.to_s

            it "does not include the '#{k}' group" do
                expect(subject.to_rpc_data).not_to include k
            end
        end
    end

    describe '#to_rpc_data_without_defaults' do
        before do
            SCNR::Engine::Options.reset
        end

        it 'returns RPC data that are not identical to default settings' do
            expect(subject.dup.reset.to_rpc_data_without_defaults).to eq subject.to_rpc_data_without_defaults

            subject.url = 'http://stuff/'
            subject.audit.elements :forms

            expect(subject.to_rpc_data_without_defaults).to eq({
                'url'   => 'http://stuff/',
                'audit' => {
                    'parameter_values'        => true,
                    'mode'                    => 'moderate',
                    'exclude_vector_patterns' => [],
                    'include_vector_patterns' => [],
                    'link_templates'          => [],
                    'forms'                   => true
                }
            })
        end
    end

    describe '#to_hash' do
        let(:data) { subject.to_hash }

        it 'converts self to a hash' do
            subject.scope.restrict_paths = 'test'
            subject.checks << 'stuff'
            subject.datastore.stuff      = 'test2'

            h = subject.to_hash
            expect(h).to be_kind_of Hash
        end

        (groups - described_class::TO_HASH_IGNORE.to_a).each do |k|
            it "includes the '#{k}' group" do
                expect(data[k]).to eq(subject.send(k).to_hash)
            end
        end

        described_class::TO_HASH_IGNORE.each do |k|
            it "does not include the '#{k}' group" do
                expect(subject.to_hash).not_to include k
            end
        end

    end

    describe '#to_h' do
        it 'aliased to to_hash' do
            expect(subject.to_hash).to eq(subject.to_h)
        end
    end

    describe '#rpc_data_to_hash' do
        it 'normalizes the given hash into #to_hash format' do
            normalized = subject.rpc_data_to_hash(
                'http' => {
                    'request_timeout' => 90_000
                }
            )

            expect(normalized[:http][:request_timeout]).to eq(90_000)
            expect(subject.http.request_timeout).not_to eq(90_000)
        end
    end

    describe '#hash_to_rpc_data' do
        it 'normalizes the given hash into #to_rpc_data format' do
            normalized = subject.hash_to_rpc_data(
                http: { request_timeout: 90_000 }
            )

            expect(normalized['http']['request_timeout']).to eq(90_000)
            expect(subject.http.request_timeout).not_to eq(90_000)
        end
    end

end
