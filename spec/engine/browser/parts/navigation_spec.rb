require 'spec_helper'

describe SCNR::Engine::Browser::Parts::Navigation do
    include_examples 'browser'

    describe '#goto' do
        let(:other){ SCNR::Engine::Browser.new }

        it 'loads the given URL' do
            subject.goto url

            expect(subject.source).to include( ua )
        end

        it 'returns a playable transition' do
            transition = subject.goto( url )

            transition.play( other )

            expect(other.source).to include( ua )
        end

        it 'does not receive a Content-Security-Policy header' do
            subject.goto "#{url}/Content-Security-Policy"
            expect(subject.response.code).to eq(200)
            expect(subject.response.headers).not_to include 'Content-Security-Policy'
        end

        context 'when there is no page URL' do
            it 'does not receive a Date header' do
                subject.watir.goto "#{url}/Date"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Date'
            end

            it 'does not receive an Etag header' do
                subject.watir.goto "#{url}/Etag"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Etag'
            end

            it 'does not receive a Cache-Control header' do
                subject.watir.goto "#{url}/Cache-Control"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Cache-Control'
            end

            it 'does not receive a Last-Modified header' do
                subject.watir.goto "#{url}/Last-Modified"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Last-Modified'
            end

            it 'does not send If-None-Match request headers' do
                subject.watir.goto "#{url}/If-None-Match"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-None-Match'

                subject.watir.goto "#{url}/If-None-Match"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-None-Match'
            end

            it 'does not send If-Modified-Since request headers' do
                subject.watir.goto "#{url}/If-Modified-Since"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-Modified-Since'

                subject.watir.goto "#{url}/If-Modified-Since"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-Modified-Since'
            end
        end

        context 'when requesting the page URL' do
            it 'does not receive a Date header' do
                subject.goto "#{url}/Date"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Date'
            end

            it 'does not receive an Etag header' do
                subject.goto "#{url}/Etag"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Etag'
            end

            it 'does not receive a Cache-Control header' do
                subject.goto "#{url}/Cache-Control"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Cache-Control'
            end

            it 'does not receive a Last-Modified header' do
                subject.goto "#{url}/Last-Modified"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Last-Modified'
            end

            it 'does not send If-None-Match request headers' do
                subject.goto "#{url}/If-None-Match"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-None-Match'

                subject.goto "#{url}/If-None-Match"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-None-Match'
            end

            it 'does not send If-Modified-Since request headers' do
                subject.goto "#{url}/If-Modified-Since"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-Modified-Since'

                subject.goto "#{url}/If-Modified-Since"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-Modified-Since'
            end
        end

        context 'when requesting something other than the page URL' do
            it 'receives a Date header' do
                url = "#{root_url}Date"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url

                expect(response.code).to eq(200)
                expect(response.headers).to include 'Date'
            end

            it 'receives an Etag header' do
                url = "#{root_url}Etag"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url

                expect(response.code).to eq(200)
                expect(response.headers).to include 'Etag'
            end

            it 'receives a Cache-Control header' do
                url = "#{root_url}Cache-Control"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url

                expect(response.code).to eq(200)
                expect(response.headers).to include 'Cache-Control'
            end

            it 'receives a Last-Modified header' do
                url = "#{root_url}Last-Modified"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url

                expect(response.code).to eq(200)
                expect(response.headers).to include 'Last-Modified'
            end

            it 'sends If-None-Match request headers' do
                url = "#{root_url}If-None-Match"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url
                subject.goto url
                expect(response.request.headers).to include 'If-None-Match'
            end

            it 'sends If-Modified-Since request headers' do
                url = "#{root_url}If-Modified-Since"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url
                subject.goto url
                expect(response.request.headers).to include 'If-Modified-Since'
            end
        end

        context 'when the page has JS timers' do
            context "and #{SCNR::Engine::OptionGroups::DOM}#wait_for_timers is" do
                context 'true' do
                    before do
                        SCNR::Engine::Options.dom.wait_for_timers = true
                    end

                    it 'executes them' do
                        expect( subject.cookies ).to be_empty
                        subject.goto "#{url}load_delay"

                        expect( subject.cookies.map(&:to_s).sort ).to eq([
                           'interval=post-1500',
                           'timeout2=post-2-2000',
                           'timeout1=post-1-1000'
                         ].sort)
                    end
                end

                context 'false' do
                    before do
                        SCNR::Engine::Options.dom.wait_for_timers = false
                    end

                    it 'does not execute them' do
                        expect( subject.cookies ).to be_empty
                        subject.goto "#{url}load_delay"

                        expect( subject.cookies.map(&:to_s) ).to be_empty
                    end
                end
            end

        end

        context 'when there are outstanding HTTP requests' do
            it 'waits for them to complete' do
                sleep_time = 5
                time = Time.now

                subject.goto "#{url}/ajax_sleep?sleep=#{sleep_time}"

                expect(Time.now - time).to be >= sleep_time
            end

            context "when requests takes more than #{SCNR::Engine::OptionGroups::HTTP}#request_timeout" do
                it 'returns false' do
                    sleep_time = 5
                    SCNR::Engine::Options.http.request_timeout = 1_000

                    allow_any_instance_of(SCNR::Engine::HTTP::ProxyServer).to receive(:has_connections?){ true }

                    time = Time.now
                    subject.goto "#{url}/ajax_sleep?sleep=#{sleep_time}"

                    expect(Time.now - time).to be < sleep_time
                end
            end
        end

        context "with #{SCNR::Engine::OptionGroups::DOM}#local_storage" do
            before do
                SCNR::Engine::Options.dom.local_storage = {
                    'name' => 'value'
                }
            end

            it 'sets the data as local storage' do
                subject.load url
                expect( subject.javascript.run( 'return localStorage.getItem( "name" )' ) ).to eq 'value'
            end
        end

        context "with #{SCNR::Engine::OptionGroups::DOM}#session_storage" do
            before do
                SCNR::Engine::Options.dom.session_storage = {
                    'name2' => 'value2'
                }
            end

            it 'sets the data as session storage' do
                subject.load url
                expect( subject.javascript.run( 'return sessionStorage.getItem( "name2" )' ) ).to eq 'value2'
            end
        end

        context "with #{SCNR::Engine::OptionGroups::DOM}#wait_for_elements" do
            context 'when the URL matches a pattern' do
                it 'waits for the element matching the CSS to appear' do
                    SCNR::Engine::Options.dom.wait_for_elements = {
                        'stuff' => '#matchThis'
                    }

                    t = Time.now
                    subject.goto( url + '/wait_for_elements#stuff/here' )
                    elapsed = Time.now - t

                    expect(elapsed).to be > 5
                    expect(elapsed).to be < 7

                    expect(subject.watir.element( css: '#matchThis' ).tag_name).to eq('button')
                end

                it "waits a maximum of #{SCNR::Engine::OptionGroups::DOM}#job_timeout" do
                    SCNR::Engine::Options.dom.wait_for_elements = {
                        'never' => '#never_appears'
                    }
                    SCNR::Engine::Options.dom.job_timeout = 2

                    t = Time.now
                    subject.goto( url + '/wait_for_elements#never/appears' )
                    expect(Time.now - t).to be < 5

                    expect do
                        subject.watir.element( css: '#never' ).tag_name
                    end.to raise_error Watir::Exception::UnknownObjectException
                end
            end

            context 'when the URL does not match any patterns' do
                it 'does not wait' do
                    SCNR::Engine::Options.dom.wait_for_elements = {
                        'stuff' => '#matchThis'
                    }

                    t = Time.now
                    subject.goto( url + '/wait_for_elements' )
                    expect(Time.now - t).to be < 5
                end
            end
        end

        context "with #{SCNR::Engine::OptionGroups::Scope}#exclude_file_extensions" do
            it 'respects scope restrictions' do
                SCNR::Engine::Options.scope.exclude_file_extensions = ['png']
                subject.load( "#{url}form-with-image-button" )
                expect(image_hit_count).to eq(0)

                SCNR::Engine::Options.scope.exclude_file_extensions = []
                subject.load( "#{url}form-with-image-button" )
                expect(image_hit_count).to be > 0
            end

            context 'but allows assets like' do
                SCNR::Engine::Browser::Parts::HTTP::ASSET_EXTENSIONS.each do |ext|
                    it ext
                end
            end
        end

        context "with #{SCNR::Engine::OptionGroups::Scope}#exclude_path_patterns" do
            it 'respects scope restrictions' do
                pages = subject.load( url + '/explore' ).start_capture.trigger_events.flush_pages
                pages_should_have_form_with_input pages, 'by-ajax'

                SCNR::Engine::Options.scope.exclude_path_patterns << /ajax/
                pages = subject.load( url + '/explore' ).start_capture.trigger_events.flush_pages
                pages_should_not_have_form_with_input pages, 'by-ajax'
            end
        end

        context "with #{SCNR::Engine::OptionGroups::Scope}#redundant_path_patterns" do
            it 'respects scope restrictions' do
                SCNR::Engine::Options.scope.redundant_path_patterns = { 'explore' => 0 }
                expect(subject.load( url + '/explore' ).response.code).to eq(0)
            end
        end

        context "with #{SCNR::Engine::OptionGroups::Scope}#auto_redundant_paths has bee configured" do
            it 'respects scope restrictions' do
                SCNR::Engine::Options.scope.auto_redundant_paths = 0
                expect(subject.load( url + '/explore?test=1&test2=2' ).response.body).to be_empty
            end
        end

        context "when the engine's #allow_request? method returns" do
            context 'true' do
                it 'allows the request to proceed' do
                    expect(subject.engine).to receive(:allow_request?).at_least(:once).and_return(true)
                    expect(subject.load( url + '/explore?test=1&test2=2' ).response.body).to_not be_empty
                end
            end

            context 'false' do
                it 'aborts the request' do
                    expect(subject.engine).to receive(:allow_request?).at_least(:once).and_return(false)
                    expect(subject.load( url + '/explore?test=1&test2=2' ).response.body).to be_empty
                end
            end
        end

        describe ':cookies' do
            it 'loads the given cookies' do
                cookie = { 'myname' => 'myvalue' }
                subject.goto url, cookies: cookie

                cookie_data = subject.cookies.
                    find { |c| c.name == cookie.keys.first }.inputs

                expect(cookie_data).to eq(cookie)
            end

            it 'includes them in the transition' do
                cookie = { 'myname' => 'myvalue' }
                transition = subject.goto( url, cookies: cookie )

                expect(transition.options[:cookies]).to eq(cookie)
            end
        end

        describe ':take_snapshot' do
            describe 'true' do
                it 'captures a snapshot of the loaded page' do
                    subject.goto url, take_snapshot: true
                    pages = subject.page_snapshots
                    expect(pages.size).to eq(1)

                    expect(pages.first.dom.transitions).to eq(transitions_from_array([
                                                                                         { page: :load }
                                                                                     ]))
                end
            end

            describe 'false' do
                it 'does not capture a snapshot of the loaded page' do
                    subject.goto url, take_snapshot:  false
                    expect(subject.page_snapshots).to be_empty
                end
            end

            describe 'default' do
                it 'does not capture a snapshot of the loaded page' do
                    subject.goto url
                    expect(subject.page_snapshots).to be_empty
                end
            end
        end

        describe ':update_transitions' do
            describe 'true' do
                it 'pushes the page load to the transitions' do
                    t = subject.goto( url, update_transitions: true )
                    expect(subject.to_page.dom.transitions).to include t
                end
            end

            describe 'false' do
                it 'does not push the page load to the transitions' do
                    t = subject.goto( url, update_transitions: false )
                    expect(subject.to_page.dom.transitions).to be_empty
                end
            end

            describe 'default' do
                it 'pushes the page load to the transitions' do
                    t = subject.goto( url )
                    expect(subject.to_page.dom.transitions).to include t
                end
            end
        end
    end

    describe '#load' do

        it 'returns self' do
            expect(subject.load( url )).to eq(subject)
        end

        it 'updates the global cookie-jar' do
            subject.load url

            cookie = SCNR::Engine::HTTP::Client.cookies.find(&:http_only?)

            expect(cookie.name).to  eq('This name should be updated; and properly escaped')
            expect(cookie.value).to eq('This value should be updated; and properly escaped')
        end

        describe ':cookies' do
            it 'loads the given cookies' do
                cookie = { 'myname' => 'myvalue' }
                subject.load url, cookies: cookie

                expect(subject.cookies.find { |c| c.name == cookie.keys.first }.inputs).to eq(cookie)
            end
        end

        describe ':take_snapshot' do
            describe 'true' do
                it 'captures a snapshot of the loaded page' do
                    subject.load url, take_snapshot: true
                    pages = subject.page_snapshots
                    expect(pages.size).to eq(1)

                    expect(pages.first.dom.transitions).to eq(transitions_from_array([
                                                                                         { page: :load }
                                                                                     ]))
                end
            end

            describe 'false' do
                it 'does not capture a snapshot of the loaded page' do
                    subject.load url, take_snapshot: false
                    expect(subject.page_snapshots).to be_empty
                end
            end

            describe 'default' do
                it 'does not capture a snapshot of the loaded page' do
                    subject.load url
                    expect(subject.page_snapshots).to be_empty
                end
            end
        end

        context 'when given a' do
            describe 'String' do
                it 'treats it as a URL' do
                    expect(hit_count).to eq(0)

                    subject.load url
                    expect(subject.source).to include( ua )
                    expect(subject.preloads).not_to include( url )

                    expect(hit_count).to eq(1)
                end

                it 'notifies of :before_load' do
                    args = nil
                    described_class.before_load do |*a|
                        args = a
                    end

                    options = {}
                    subject.load( url, options )

                    r, o, b = *args

                    expect(url).to be r
                    expect(options).to be o
                    expect(subject).to be b
                end

                it 'notifies of :after_load' do
                    args = nil
                    described_class.after_load do |*a|
                        args = a
                    end

                    options = {}
                    subject.load( url, options )

                    r, o, b = *args

                    expect(url).to be r
                    expect(options).to be o
                    expect(subject).to be b
                end
            end

            describe 'Engine::HTTP::Response' do
                let(:resource) do
                    SCNR::Engine::HTTP::Client.get( url, mode: :sync )
                end

                it 'loads it' do
                    expect(hit_count).to eq(0)

                    subject.load resource
                    expect(subject.source).to include( ua )
                    expect(subject.preloads).not_to include( url )

                    expect(hit_count).to eq(1)
                end

                it 'notifies of :before_load' do
                    args = nil
                    described_class.before_load do |*a|
                        args = a
                    end

                    options = {}
                    subject.load( resource, options )

                    r, o, b = *args

                    expect(resource).to be r
                    expect(options).to be o
                    expect(subject).to be b
                end

                it 'notifies of :after_load' do
                    args = nil
                    described_class.after_load do |*a|
                        args = a
                    end

                    options = {}
                    subject.load( resource, options )

                    r, o, b = *args

                    expect(resource).to be r
                    expect(options).to be o
                    expect(subject).to be b
                end
            end

            describe 'Engine::Page::DOM' do
                let(:resource) do
                    SCNR::Engine::HTTP::Client.get( url, mode: :sync ).to_page.dom
                end

                it 'loads it' do
                    expect(hit_count).to eq(0)
                    resource
                    expect(hit_count).to eq(1)

                    subject.load resource

                    expect(subject.source).to include( ua )
                    expect(subject.preloads).not_to include( url )

                    expect(hit_count).to eq(2)
                end

                it 'notifies of :before_load' do
                    args = nil
                    described_class.before_load do |*a|
                        args = a
                    end

                    options = {}
                    subject.load( resource, options )

                    r, o, b = *args

                    expect(resource).to be r
                    expect(options).to be o
                    expect(subject).to be b
                end

                it 'notifies of :after_load' do
                    args = nil
                    described_class.after_load do |*a|
                        args = a
                    end

                    options = {}
                    subject.load( resource, options )

                    r, o, b = *args

                    expect(resource).to be r
                    expect(options).to be o
                    expect(subject).to be b
                end

                it 'replays its #transitions' do
                    subject.load "#{url}play-transitions"
                    page = subject.explore_and_flush.last
                    expect(page.body).to include ua

                    subject.load page.dom
                    expect(subject.source).to include ua

                    page.dom.transitions.clear
                    subject.load page.dom
                    expect(subject.source).not_to include ua
                end

                it 'loads its #skip_states' do
                    subject.load( url )
                    pages = subject.load( url + '/explore' ).trigger_events.
                        page_snapshots

                    page = pages.last
                    expect(Set.new( page.dom.skip_states.collection.to_a )).to be_subset Set.new( subject.skip_states.collection.to_a )

                    token = subject.generate_token

                    dpage = page.dup
                    dpage.dom.skip_states << token

                    subject.load dpage.dom
                    expect(subject.skip_states).to include token
                end
            end

            describe 'Engine::Page' do
                it 'loads it' do
                    expect(hit_count).to eq(0)

                    page = SCNR::Engine::HTTP::Client.get( url, mode: :sync ).to_page

                    expect(hit_count).to eq(1)

                    subject.load page

                    expect(subject.source).to include( ua )
                    expect(subject.preloads).not_to include( url )

                    expect(hit_count).to eq(2)
                end

                it 'uses its #cookie_jar' do
                    expect(subject.cookies).to be_empty

                    cookie = SCNR::Engine::Cookie.new(
                        url:    url,
                        inputs: {
                            'my-name' => 'my-value'
                        }
                    )

                    page = SCNR::Engine::Page.from_data(
                        url:        url,
                        cookie_jar:  [ cookie ]
                    )

                    expect(subject.cookies).to_not include cookie

                    subject.load( page )

                    expect(subject.cookies).to include cookie
                end

                it 'replays its DOM#transitions' do
                    subject.load "#{url}play-transitions"
                    page = subject.explore_and_flush.last
                    expect(page.body).to include ua

                    subject.load page
                    expect(subject.source).to include ua

                    page.dom.transitions.clear
                    subject.load page
                    expect(subject.source).not_to include ua
                end

                it 'loads its DOM#skip_states' do
                    subject.load( url )
                    pages = subject.load( url + '/explore' ).trigger_events.
                        page_snapshots

                    page = pages.last
                    expect(Set.new( page.dom.skip_states.collection.to_a )).to be_subset Set.new( subject.skip_states.collection.to_a )

                    token = subject.generate_token

                    dpage = page.dup
                    dpage.dom.skip_states << token

                    subject.load dpage
                    expect(subject.skip_states).to include token
                end
            end

            describe 'other' do
                it 'raises Engine::Browser::Error::Load' do
                    expect { subject.load [] }.to raise_error SCNR::Engine::Browser::Parts::Navigation::Error::Load
                end
            end
        end
    end

    describe '#preload' do
        it 'removes entries after they are used' do
            subject.preload SCNR::Engine::HTTP::Client.get( url, mode: :sync )
            clear_hit_count

            expect(hit_count).to eq(0)

            subject.load url
            expect(subject.source).to include( ua )
            expect(subject.preloads).not_to include( url )

            expect(hit_count).to eq(0)

            2.times do
                subject.load url
                expect(subject.source).to include( ua )
            end

            expect(subject.preloads).not_to include( url )

            expect(hit_count).to eq(2)
        end

        it 'returns the URL of the resource' do
            response = SCNR::Engine::HTTP::Client.get( url, mode: :sync )
            expect(subject.preload( response )).to eq(response.url)

            subject.load response.url
            expect(subject.source).to include( ua )
        end

        context 'when given a' do
            describe 'Engine::HTTP::Response' do
                it 'preloads it' do
                    subject.preload SCNR::Engine::HTTP::Client.get( url, mode: :sync )
                    clear_hit_count

                    expect(hit_count).to eq(0)

                    subject.load url
                    expect(subject.source).to include( ua )
                    expect(subject.preloads).not_to include( url )

                    expect(hit_count).to eq(0)
                end
            end

            describe 'Engine::Page' do
                it 'preloads it' do
                    subject.preload SCNR::Engine::Page.from_url( url )
                    clear_hit_count

                    expect(hit_count).to eq(0)

                    subject.load url
                    expect(subject.source).to include( ua )
                    expect(subject.preloads).not_to include( url )

                    expect(hit_count).to eq(0)
                end
            end

            describe 'other' do
                it 'raises Engine::Browser::Error::Load' do
                    expect { subject.preload [] }.to raise_error SCNR::Engine::Browser::Parts::Navigation::Error::Load
                end
            end
        end
    end

end
