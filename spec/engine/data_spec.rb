require 'spec_helper'

describe SCNR::Engine::Data do

    subject { described_class }
    let(:dump_directory) do
        "#{Dir.tmpdir}/data-#{SCNR::Engine::Utilities.generate_token}/"
    end

    describe '#framework' do
        it "returns an instance of #{described_class::Framework}" do
            expect(subject.framework).to be_kind_of described_class::Framework
        end
    end

    describe '#session' do
        it "returns an instance of #{described_class::Session}" do
            expect(subject.session).to be_kind_of described_class::Session
        end
    end

    describe '#issues' do
        it "returns an instance of #{described_class::Issues}" do
            expect(subject.issues).to be_kind_of described_class::Issues
        end
    end

    describe '#plugins' do
        it "returns an instance of #{described_class::Plugins}" do
            expect(subject.plugins).to be_kind_of described_class::Plugins
        end
    end

    describe '#browser_pool' do
        it "returns an instance of #{described_class::BrowserPool}" do
            expect(subject.browser_pool).to be_kind_of described_class::BrowserPool
        end
    end

    describe '#statistics' do
        %w(framework issues plugins browser_pool session).each do |name|
            it "includes :#{name} statistics" do
                expect(subject.statistics[name.to_sym]).to eq(subject.send(name).statistics)
            end
        end
    end

    describe '.dump' do
        %w(framework issues plugins session browser_pool).each do |name|
            it "stores ##{name} to disk" do
                previous_instance = subject.send(name)

                subject.dump( dump_directory )

                new_instance = subject.load( dump_directory ).send(name)

                expect(new_instance).to be_kind_of subject.send(name).class
                expect(new_instance.object_id).not_to eq(previous_instance.object_id)
            end
        end
    end

    describe '#clear' do
        %w(framework issues plugins session browser_pool).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear).at_least(:once)
                subject.clear
            end
        end
    end
end
