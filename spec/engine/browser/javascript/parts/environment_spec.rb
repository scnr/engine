require 'spec_helper'

describe SCNR::Engine::Browser::Javascript::Parts::Environment do
    include_examples 'javascript'

    describe '#custom_code' do
        it 'injects the given code into the response' do
            subject.custom_code = 'window.has_custom_code = true'
            browser.load "#{taint_tracer_url}/debug"
            expect(subject.run( 'return window.has_custom_code' )).to eq(true)
        end
    end

    describe '#supported?' do
        context 'when there is support for the Javascript environment' do
            it 'returns true' do
                browser.load "#{taint_tracer_url}/debug"
                expect(subject.supported?).to be_truthy
            end
        end

        context 'when there is no support for the Javascript environment' do
            it 'returns false' do
                browser.load "#{taint_tracer_url}/without_javascript_support"
                expect(subject.supported?).to be_falsey
            end
        end

        context 'when the resource is out-of-scope' do
            it 'returns false' do
                SCNR::Engine::Options.url = taint_tracer_url
                browser.load 'http://google.com/'
                expect(subject.supported?).to be_falsey
            end
        end
    end

    describe '#wait_till_ready' do
        it 'waits until the JS environment is #ready?'

        context 'when it exceeds Options.browser_cluster.job_timeout' do
            it 'returns' do
                SCNR::Engine::Options.browser_cluster.job_timeout = 5
                browser.load "#{taint_tracer_url}/debug"

                allow(subject).to receive(:ready?) { false }

                t = Time.now
                subject.wait_till_ready

                expect(Time.now - t).to be > 5
                expect(Time.now - t).to be < 6
            end
        end
    end

end
