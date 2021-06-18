shared_examples_for 'auditable_dom' do
    it_should_behave_like 'auditable'

    before(:each) { enable_dom }

    describe '#with_browser_pool' do
        context 'when a browser cluster is' do
            context 'available' do
                it 'passes a BrowserPool to the given block' do
                    worker = nil

                    subject.with_browser_pool do |cluster|
                        worker = cluster
                    end

                    expect(worker).to eq(subject.auditor.browser_pool)
                end
            end
        end
    end

    describe '#with_browser' do
        context 'when a browser cluster is' do
            context 'available' do
                it 'passes a BrowserPool::Worker to the given block' do
                    worker = nil

                    expect(subject.with_browser do |browser|
                        worker = browser
                    end).to be_truthy
                    subject.auditor.browser_pool.wait

                    expect(worker).to be_kind_of SCNR::Engine::BrowserPool::Worker
                end
            end
        end
    end

    describe '#auditor' do
        it 'returns the assigned auditor' do
            expect(subject.auditor).to be_kind_of SCNR::Engine::Check::Auditor
        end
    end
end
