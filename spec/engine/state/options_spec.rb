require 'spec_helper'

describe SCNR::Engine::State::Options do

    subject { described_class.new }
    let(:dump_directory) do
        "#{Dir.tmpdir}/options-#{SCNR::Engine::Utilities.generate_token}"
    end

    it { is_expected.to respond_to :clear}

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes :url' do
            SCNR::Engine::Options.url = 'http://test/'
            expect(statistics[:url]).to eq(SCNR::Engine::Options.url)
        end

        it 'includes :checks' do
            SCNR::Engine::Options.checks = %w(xss* sql_injection)
            expect(statistics[:checks]).to eq(SCNR::Engine::Options.checks)
        end

        it 'includes :plugins' do
            SCNR::Engine::Options.plugins = { 'form_login' => {} }
            expect(statistics[:plugins]).to eq(%w(form_login))
        end
    end

    describe '#dump' do
        it 'stores to disk' do
            SCNR::Engine::Options.datastore.my_custom_option = 'my value'
            subject.dump( dump_directory )

            expect(SCNR::Engine::Options.load( "#{dump_directory}/options" ).
                datastore.my_custom_option).to eq('my value')
        end
    end

    describe '.load' do
        it 'restores from disk' do
            SCNR::Engine::Options.datastore.my_custom_option = 'my value'
            subject.dump( dump_directory )

            described_class.load( dump_directory )

            expect(SCNR::Engine::Options.datastore.my_custom_option).to eq('my value')
        end
    end

end
