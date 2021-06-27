require 'spec_helper'

describe SCNR::Engine::Framework::Parts::Browser do
    include_examples 'framework'

    describe '#browser_pool' do
        context 'when #use_browsers? is' do
            context 'true' do
                before do
                    allow(subject).to receive(:use_browsers?) { true }
                end

                it "returns #{SCNR::Engine::BrowserPool}" do
                    expect(subject.browser_pool).to be_kind_of SCNR::Engine::BrowserPool
                end
            end

            context 'false' do
                before do
                    allow(subject).to receive(:use_browsers?) { false }
                end

                it 'returns nil' do
                    expect(subject.browser_pool).to be_nil
                end
            end
        end

        context 'when the page queue is empty' do
            it 'prefers jobs from the crawl category'
        end

        context 'when the page queue size is less than the memory buffer' do
            it 'prefers jobs from the crawl category'
        end
    end

    describe '#use_browsers?' do
        before :each do
            SCNR::Engine::Options.scope.dom_depth_limit = 1
            SCNR::Engine::Options.dom.pool_size         = 1
        end

        context "when #{SCNR::Engine::OptionGroups::DOM}#enabled? is" do
            context 'false' do
                before do
                    SCNR::Engine::Options.dom.pool_size = 0
                end

                it 'returns false' do
                    expect(subject.use_browsers?).to be_falsey
                end
            end

            context 'true' do
                before do
                    SCNR::Engine::Options.dom.pool_size = 1
                end

                it 'returns true' do
                    expect(subject.use_browsers?).to be_truthy
                end
            end
        end

        context "when #{SCNR::Engine::OptionGroups::Scope}#dom_depth_limit is" do
            context '0' do
                before do
                    SCNR::Engine::Options.scope.dom_depth_limit = 0
                end

                it 'returns false' do
                    expect(subject.use_browsers?).to be_falsey
                end
            end

            context '> 0' do
                before do
                    SCNR::Engine::Options.scope.dom_depth_limit = 1
                end

                it 'returns true' do
                    expect(subject.use_browsers?).to be_truthy
                end
            end
        end
    end
end
