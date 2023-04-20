require 'spec_helper'

describe SCNR::Engine::Trainer::SinkTracer do

    before :each do
        SCNR::Engine::Element::Capabilities::WithSinks::Sinks.enable_all
        SCNR::Engine::Element::Capabilities::WithSinks::Sinks.add_to_max_cost 9999
    end

    subject do
        described_class.new
    end

    let(:page) do
        p = Factory[:page]
        p.elements.each do |e|
            e.action = 'http://localhost/'
        end
        p
    end

    describe '#process' do
        context 'when the page has elements' do
            context 'that are in scope' do
                before do
                    SCNR::Engine::Options.audit.elements :links
                end

                context 'and have inputs' do
                    context 'and respond to sinks' do

                        context "and #{SCNR::Engine::OptionGroups::Audit}#paranoia" do
                            context 'is set to' do
                                context ':low' do
                                    it 'traces them'
                                end

                                context ':medium' do
                                    it 'traces them'
                                end

                                context ":high" do
                                    it 'does not trace them'
                                end
                            end
                        end

                        context 'and have not already been traced' do
                            it 'traces them' do
                                subject.process page
                                subject.http.run

                                page.links.each do |e|
                                    expect(e.sinks).to be_traced
                                end

                                (page.forms + page.cookies + page.headers).each do |e|
                                    expect(e.sinks).not_to be_traced
                                end
                            end
                        end

                        context 'and have already already been traced' do
                            it 'does not trace them' do
                                page.elements.each do |e|
                                    allow_any_instance_of(e.class::Sinks).to receive(:traced?) { true }
                                    expect_any_instance_of(e.class::Sinks).not_to receive(:trace)
                                end

                                subject.process page
                            end
                        end
                    end
                end

                context 'and have no inputs' do
                    it 'does not trace them' do
                        page.links.each do |e|
                            e.inputs = {}
                            expect_any_instance_of(e.class::Sinks).not_to receive(:trace)
                        end

                        subject.process page
                    end
                end
            end

            context 'that are out of scope' do
                before do
                    SCNR::Engine::Options.audit.skip_elements :links, :forms, :cookies, :headers, :nested_cookies
                end

                it 'does not trace them' do
                    page.elements.each do |e|
                        expect_any_instance_of(e.class::Sinks).not_to receive(:trace)
                    end

                    subject.process page
                end
            end
        end
    end

end
