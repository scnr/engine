require 'spec_helper'

class TrainerMockFramework
    attr_reader :pages
    attr_reader :urls
    attr_reader :options
    attr_reader :trainer

    attr_accessor :sitemap

    def initialize( page = nil )
        @page        = page
        @pages       = []
        @on_page_audit = []

        http.reset
        @trainer = SCNR::Engine::Trainer.new
        @trainer.framework = self
        @trainer.setup

        @options = SCNR::Engine::Options.instance
        @options.url = page.url if page

        @sitemap = []
        @urls    = []
    end

    def accepts_more_pages?
        @options.scope.crawl? && !@options.scope.page_limit_reached?( @sitemap.size )
    end

    def run
        @on_page_audit.each do |b|
            b.call @page
        end

        http.run
    end

    def http
        SCNR::Engine::HTTP::Client
    end

    def on_page_audit( &block )
        @on_page_audit << block
    end

    def push_to_page_queue( page )
        @sitemap << page.url
        @pages << page
    end

    def push_to_url_queue( url )
        @urls << url
    end
end

def request( url )
    SCNR::Engine::HTTP::Client.get( url.to_s, mode: :sync )
end

describe SCNR::Engine::Trainer do

    before( :each ) do
        SCNR::Engine::Options.audit.elements :links, :forms, :cookies, :headers
    end

    let(:subject) { framework.trainer }
    let(:framework) { TrainerMockFramework.new( page ) }
    let(:page) { SCNR::Engine::Page.from_url( url ) }
    let(:url) { web_server_url_for( :trainer ) }

    describe 'HTTP requests with "train" set to' do
        describe 'nil' do
            context 'and is not buffered' do
                it 'skips the Trainer' do
                    expect(framework.pages.size).to eq(0)

                    SCNR::Engine::HTTP::Client.request( url + '/elems' )
                    framework.run

                    expect(framework.pages.size).to eq(0)
                end
            end

            context 'and is buffered' do
                it 'skips the Trainer' do
                    expect(framework.pages.size).to eq(0)

                    SCNR::Engine::HTTP::Client.request(
                        url + '/elems',
                        on_body: proc {}
                    )
                    framework.run

                    expect(framework.pages.size).to eq(0)
                end
            end
        end
        describe 'false' do
            context 'and is not buffered' do
                it 'skips the Trainer' do
                    expect(framework.pages.size).to eq(0)

                    SCNR::Engine::HTTP::Client.request( url + '/elems', train: false )
                    framework.run

                    expect(framework.pages.size).to eq(0)
                end
            end

            context 'and is buffered' do
                it 'skips the Trainer' do
                    expect(framework.pages.size).to eq(0)

                    SCNR::Engine::HTTP::Client.request(
                        url + '/elems',
                        train:   false,
                        on_body: proc {}
                    )
                    framework.run

                    expect(framework.pages.size).to eq(0)
                end
            end
        end

        describe 'true' do
            context 'and is not buffered' do
                it 'passes the response to the Trainer' do
                    expect(framework.pages.size).to eq(0)

                    SCNR::Engine::HTTP::Client.request( url + '/elems', train: true )

                    expect(subject).to receive(:push)
                    framework.run
                end

                context 'when a redirection leads to new elements' do
                    it 'passes the response to the Trainer' do
                        expect(framework.pages.size).to eq(0)

                        SCNR::Engine::HTTP::Client.request( url + '/train/redirect', train: true )
                        framework.run
                        framework.trainer.wait

                        page = framework.pages.first
                        expect(page.links.first.inputs.include?( 'msg' )).to be_truthy
                    end
                end
            end

            # context 'and is buffered' do
                # it 'is ignored' do
                #     expect(framework.pages.size).to eq(0)
                #
                #     SCNR::Engine::HTTP::Client.request(
                #         url + '/elems',
                #         train:   true,
                #         on_body: proc {}
                #     )
                #
                #     expect(subject).to_not receive(:analyze)
                #     framework.run
                #     framework.trainer.wait
                # end
                #
                # it 'passes the response to the Trainer' do
                #     expect(framework.pages.size).to eq(0)
                #
                #     SCNR::Engine::HTTP::Client.request(
                #         url + '/elems',
                #         train:   true,
                #         on_body: proc {}
                #     )
                #
                #     expect(subject).to receive(:analyze)
                #     framework.run
                # end
                #
                # context 'when a redirection leads to new elements' do
                #     it 'passes the response to the Trainer' do
                #         expect(framework.pages.size).to eq(0)
                #
                #         SCNR::Engine::HTTP::Client.request(
                #             url + '/train/redirect',
                #             train:   true,
                #             on_body: proc {}
                #         )
                #         framework.run
                #
                #         page = framework.pages.first
                #         expect(page.links.first.inputs.include?( 'msg' )).to be_truthy
                #     end
                # end
            # end
        end
    end

    context 'when a page' do
        context 'has not changed' do
            it 'is skipped' do
                expect(framework.pages).to be_empty

                SCNR::Engine::HTTP::Client.request( url, train: true )
                framework.run

                expect(framework.pages).to be_empty
            end

            context 'but has new paths' do
                it 'pushes them to the framework' do
                    expect(framework.urls).to be_empty

                    SCNR::Engine::HTTP::Client.request( url, train: true )

                    SCNR::Engine::HTTP::Client.request( url + '/new-paths', train: true )
                    framework.run
                    framework.trainer.wait

                    expect(framework.pages).to be_empty
                    expect(framework.urls).to be_any
                end
            end
        end

        context 'gets updated more than Trainer::MAX_TRAININGS_PER_URL times' do
            it 'is ignored' do
                get_response = proc do
                    SCNR::Engine::HTTP::Response.new(
                        url: url,
                        body:    "<a href='?#{rand( 9999 )}=1'>Test</a>",
                        headers: { 'Content-type' => 'text/html' },
                        request: SCNR::Engine::HTTP::Request.new( url: url )
                    )
                end

                subject.process SCNR::Engine::Page.from_response( get_response.call )

                pages = []
                subject.on_new_page { |p| pages << p }

                100.times { subject.push( get_response.call ) }
                framework.trainer.wait

                expect(pages.size).to eq(SCNR::Engine::Trainer::MAX_TRAININGS_PER_URL)
            end
        end

        context 'matches excluding criteria' do
            it 'is ignored' do
                res = SCNR::Engine::HTTP::Response.new(
                    url: url + '/exclude_me'
                )
                expect(subject.push( res )).to be_falsey
            end
        end

        context 'matches a redundancy filter' do
            it 'should not be analyzed more than the specified amount of times' do
                SCNR::Engine::Options.url = 'http://stuff.com'
                trainer = TrainerMockFramework.new.trainer

                get_response = proc do
                    SCNR::Engine::HTTP::Response.new(
                        url: 'http://stuff.com/match_this',
                        body:          "<a href='?#{rand( 9999 )}=1'>Test</a>",
                        headers: { 'Content-type' => 'text/html' },
                        request:      SCNR::Engine::HTTP::Request.new( url: 'http://stuff.com/match_this' )
                    )
                end

                subject.process SCNR::Engine::Page.from_response( get_response.call )

                pages = []
                subject.on_new_page { |p| pages << p }

                SCNR::Engine::Options.scope.redundant_path_patterns = { /match_this/ => 0 }
                subject.push( get_response.call )

                expect(pages.size).to eq(0)
            end
        end
    end

    describe '#push' do
        context 'when an error occurs' do
            it 'returns nil' do
                subject.process page

                allow(subject).to receive(:analyze_response?) { raise }

                expect(subject.push( request( url ) )).to be_nil
            end
        end

        context 'when the response has already been seen' do
            before :each do
                subject.process page

                r = request( url )
                expect(subject).to receive(:analyze).with(r)
                expect(subject.push( r )).to be_truthy
            end

            it 'returns nil' do
                r = request( url )
                expect(subject).to_not receive(:analyze)
                expect(subject.push( r )).to be_nil
            end

            context 'but URL param names are different' do
                it 'returns true' do
                    r = request( "#{url}/?stuff=1" )
                    expect(subject).to receive(:analyze).with(r)
                    expect(subject.push( r )).to be_truthy
                    subject.wait
                end
            end

            context 'but cookie names are different' do
                it 'returns true' do
                    r = request( url )
                    r.headers['set-cookie'] = 'name=val'

                    expect(subject).to receive(:analyze).with(r)
                    expect(subject.push( r )).to be_truthy
                    subject.wait
                end
            end

            context 'but the body is different' do
                it 'returns true' do
                    r = request( url )
                    r.body = '1'

                    expect(subject).to receive(:analyze).with(r)
                    expect(subject.push( r )).to be_truthy
                    subject.wait
                end
            end
        end

        context 'when the resource is out-of-scope' do
            it 'returns false' do
                subject.process page

                SCNR::Engine::Options.scope.exclude_path_patterns = url
                expect(subject.push( request( url ) )).to be_falsey
            end
        end

        context 'when the content-type is' do
            context 'text-based' do
                it 'returns true' do
                    subject.process page
                    expect(subject.push( request( url ) )).to be_truthy
                end
            end

            context 'not text-based' do
                it 'returns false' do
                    ct = url + '/non_text_content_type'
                    expect(subject.push( request( ct ) )).to be_falsey
                end
            end
        end

        context 'when the response contains a new' do
            context 'form' do
                it 'returns a page with the new form' do
                    subject.process page
                    expect(subject.push( request( url + '/new_form' ) )).to be_truthy
                    subject.wait

                    p = framework.pages.pop
                    new_forms = (p.forms - page.forms)
                    expect(new_forms.size).to eq(1)
                    expect(new_forms.first.inputs.include?( 'input2' )).to be_truthy
                end
            end

            context 'link' do
                it 'returns a page with the new link' do
                    subject.process page
                    expect(subject.push( request( url + '/new_link' ) )).to be_truthy
                    subject.wait

                    p = framework.pages.pop

                    new_links = (p.links - page.links)
                    expect(new_links.size).to eq(1)
                    expect(new_links.select { |l| l.inputs.include?( 'link_param' ) }).to be_any
                end
            end

            context 'cookie' do
                it 'returns a page with the new cookie appended' do
                    subject.process page
                    expect(subject.push( request( url + '/new_cookie' ) )).to be_truthy
                    subject.wait

                    p = framework.pages.pop
                    expect(p.cookies.size).to eq(2)
                    expect(p.cookies.select { |l| l.inputs.include?( 'new_cookie' ) }).to be_any
                end
            end
        end

        context 'when the response is the result of a redirection' do
            it 'extracts query vars from the effective url' do
                subject.process page
                expect(subject.push( request( url + '/redirect?redirected=true' ) )).to be_truthy
                subject.wait

                page = framework.pages.first
                expect(page.links.last.inputs['redirected']).to eq('true')
            end
        end

        context "when #{SCNR::Engine::Framework}#accepts_more_pages?" do
            get_response = proc do
                SCNR::Engine::HTTP::Response.new(
                    url:     "http://stuff.com/#{rand( 9999 )}",
                    body:    "<a href='?#{rand( 9999 )}=1'>Test</a>",
                    headers: { 'Content-type' => 'text/html' },
                    request: SCNR::Engine::HTTP::Request.new( url: 'http://stuff.com/match_this' )
                )
            end

            before do
                SCNR::Engine::Options.url = 'http://stuff.com'
                subject.process SCNR::Engine::Page.from_response( get_response.call )
            end

            let(:subject) { TrainerMockFramework.new.trainer }

            context 'true' do
                before { allow_any_instance_of(TrainerMockFramework).to receive(:accepts_more_pages?){ true } }

                it 'processes pages' do
                    pages = []
                    subject.on_new_page { |p| pages << p }

                    expect(subject.push( get_response.call )).to be_truthy
                    subject.wait

                    expect(pages.size).to eq(1)
                end
            end

            context 'false' do
                before { allow_any_instance_of(TrainerMockFramework).to receive(:accepts_more_pages?){ false } }

                it 'does not process the page' do
                    pages = []
                    subject.on_new_page { |p| pages << p }

                    expect(subject.push( get_response.call )).to be_falsey
                    subject.wait

                    expect(pages).to be_empty
                end
            end
        end
    end

    describe '#process' do
        it "forwards the page to #{described_class::SinkTracer}" do
            page = request( url ).to_page

            expect_any_instance_of(described_class::SinkTracer).to receive(:process).with( page )
            subject.process( page )
        end
    end
end
