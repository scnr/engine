require 'spec_helper'

describe SCNR::Engine::Browser::Parts::Events do
    include_examples 'browser'

    def selenium_to_locator( element )
        SCNR::Engine::Browser::ElementLocator.from_html( element.opening_tag )
    end

    after { described_class.reset }

    describe '#each_element_with_events' do
        before :each do
            subject.load url
        end
        let(:elements_with_events) do
            elements_with_events = []
            subject.each_element_with_events do |*info|
                elements_with_events << info
            end
            elements_with_events
        end

        let(:url) { root_url + '/trigger_events' }
        it 'passes each element and event info to the block' do
            expect(elements_with_events).to eq([
                                                   [
                                                       SCNR::Engine::Browser::ElementLocator.new(
                                                           tag_name:   'body',
                                                           attributes: { 'onmouseover' => 'makePOST();' }
                                                       ),
                                                       { mouseover: ['makePOST();'] }
                                                   ],
                                                   [
                                                       SCNR::Engine::Browser::ElementLocator.new(
                                                           tag_name:   'div',
                                                           attributes: { 'id' => 'my-div', 'onclick' => 'addForm();' }
                                                       ),
                                                       { click: ['addForm();']}
                                                   ]
                                               ])
        end

        context ':a' do
            context 'and the href is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { root_url + '/each_element_with_events/a/href/javascript' }

                    it 'includes the :click event' do
                        expect(elements_with_events).to eq([
                                                               [
                                                                   SCNR::Engine::Browser::ElementLocator.new(
                                                                       tag_name:   'a',
                                                                       attributes: { 'href' => 'javascript:doStuff()' }
                                                                   ),
                                                                   {click: [ 'javascript:doStuff()']}
                                                               ]
                                                           ])
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { root_url + '/each_element_with_events/a/href/regular' }

                    it 'is ignored' do
                        expect(elements_with_events).to be_empty
                    end
                end

                context 'and is out of scope' do
                    let(:url) { root_url + '/each_element_with_events/a/href/out-of-scope' }

                    it 'is ignored' do
                        expect(elements_with_events).to be_empty
                    end
                end
            end
        end

        context ':form' do
            context ':input' do
                context 'of type "image"' do
                    let(:url) { root_url + '/each_element_with_events/form/input/image' }

                    it 'includes the :click event' do
                        expect(elements_with_events).to eq([
                                                               [
                                                                   SCNR::Engine::Browser::ElementLocator.new(
                                                                       tag_name:   'input',
                                                                       attributes: {
                                                                           'type' => 'image',
                                                                           'name' => 'myImageButton',
                                                                           'src'  => '/__sinatra__/404.png'
                                                                       }
                                                                   ),
                                                                   {click: ['image']}
                                                               ]
                                                           ])
                    end
                end
            end

            context 'and the action is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { root_url + '/each_element_with_events/form/action/javascript' }

                    it 'includes the :submit event' do
                        expect(elements_with_events).to eq([
                                                               [
                                                                   SCNR::Engine::Browser::ElementLocator.new(
                                                                       tag_name:   'form',
                                                                       attributes: {
                                                                           'action' => 'javascript:doStuff()'
                                                                       }
                                                                   ),
                                                                   {submit: ['javascript:doStuff()']}
                                                               ]
                                                           ])
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { root_url + '/each_element_with_events/form/action/regular' }

                    it 'is ignored' do
                        expect(elements_with_events).to be_empty
                    end
                end

                context 'and is out of scope' do
                    let(:url) { root_url + '/each_element_with_events/form/action/out-of-scope' }

                    it 'is ignored' do
                        expect(elements_with_events).to be_empty
                    end
                end
            end
        end
    end

    describe '#trigger_event' do
        it 'triggers the given event on the given tag and captures snapshots' do
            subject.load( url + '/trigger_events' ).start_capture

            locators = []
            subject.selenium.find_elements(:css, '*').each do |element|
                begin
                    locators << SCNR::Engine::Browser::ElementLocator.from_html( element.opening_tag )
                rescue
                end
            end

            locators.each do |element|
                SCNR::Engine::Browser::Javascript::EVENTS.each do |e|
                    begin
                        subject.trigger_event subject.to_page, element, e
                    rescue
                        next
                    end
                end
            end

            pages_should_have_form_with_input subject.page_snapshots, 'by-ajax'
            pages_should_have_form_with_input subject.captured_pages, 'ajax-token'
        end
    end

    describe '#trigger_events' do
        it 'returns self' do
            expect(subject.load( url + '/explore' ).trigger_events).to eq(subject)
        end

        it 'waits for AJAX requests to complete' do
            subject.load( url + '/trigger_events-wait-for-ajax' ).start_capture.trigger_events

            pages_should_have_form_with_input subject.captured_pages, 'ajax-token'
            pages_should_have_form_with_input subject.page_snapshots, 'by-ajax'
        end

        it 'triggers all events on all elements' do
            subject.load( url + '/trigger_events' ).start_capture.trigger_events

            pages_should_have_form_with_input subject.page_snapshots, 'by-ajax'
            pages_should_have_form_with_input subject.captured_pages, 'ajax-token'
            pages_should_have_form_with_input subject.captured_pages, 'post-name'
        end

        it 'assigns the proper page transitions' do
            pages = subject.load( url + '/explore', take_snapshot: true ).trigger_events.page_snapshots

            expect(pages.map(&:dom).map(&:transitions)).to eq([
                                                                  [
                                                                      { :page => :load },
                                                                      { "#{url}explore" => :request }
                                                                  ],
                                                                  [
                                                                      { :page => :load },
                                                                      { "#{url}explore" => :request },
                                                                      {
                                                                          {
                                                                              tag_name: 'div',
                                                                              attributes: {
                                                                                  'id'      => 'my-div',
                                                                                  'onclick' => 'addForm();'
                                                                              }
                                                                          } => :click
                                                                      },
                                                                      { "#{url}get-ajax?ajax-token=my-token" => :request }
                                                                  ],
                                                                  [
                                                                      { :page => :load },
                                                                      { "#{url}explore" => :request },
                                                                      {
                                                                          {
                                                                              tag_name: 'a',
                                                                              attributes: {
                                                                                  'href' => 'javascript:inHref();'
                                                                              }
                                                                          } => :click
                                                                      },
                                                                      { "#{url}href-ajax" => :request }
                                                                  ]
                                                              ].map { |transitions| transitions_from_array( transitions ) })
        end

        it 'follows all javascript links' do
            subject.load( url + '/explore' ).start_capture.trigger_events

            pages_should_have_form_with_input subject.page_snapshots, 'by-ajax'
            pages_should_have_form_with_input subject.page_snapshots, 'from-post-ajax'
            pages_should_have_form_with_input subject.captured_pages, 'ajax-token'
            pages_should_have_form_with_input subject.captured_pages, 'href-post-name'
        end

        it 'captures pages from new windows' do
            pages = subject.load( url + '/explore-new-window' ).
                start_capture.trigger_events.flush_pages

            pages_should_have_form_with_input pages, 'in-old-window'
            pages_should_have_form_with_input pages, 'in-new-window'
        end

        context 'when submitting forms using an image input' do
            it 'includes x, y coordinates' do
                subject.load( "#{url}form-with-image-button" ).start_capture.trigger_events
                pages_should_have_form_with_input subject.captured_pages, 'myImageButton.x'
                pages_should_have_form_with_input subject.captured_pages, 'myImageButton.y'
            end
        end

        context 'when OptionGroups::Scope#dom_event_limit' do
            context 'has been set' do
                it 'only triggers that amount of events' do
                    SCNR::Engine::Options.scope.dom_event_limit = 1

                    subject.load( "#{url}form-with-image-button", take_snapshot: true ).start_capture.trigger_events

                    expect(subject.flush_pages.size).to eq 1
                end
            end

            context 'has not been set' do
                it 'triggers all events' do
                    SCNR::Engine::Options.scope.dom_event_limit = nil

                    subject.load( "#{url}form-with-image-button", take_snapshot: true ).start_capture.trigger_events

                    expect(subject.flush_pages.size).to eq 2
                end
            end
        end
    end

    describe '#fire_event' do
        let(:url) { "#{root_url}/trigger_events" }
        before(:each) do
            subject.load url
        end

        it 'notifies of :before_event' do
            args = nil
            described_class.before_event do |*a|
                args = a
            end

            locator = selenium_to_locator( subject.selenium.find_element( id: 'my-div' ) )
            options = {}
            event = :click

            subject.fire_event locator, event, options

            l, e, opts, browser = *args

            expect(locator).to be l
            expect(event).to be e
            expect(options).to be opts
            expect(browser).to be subject
        end

        it 'notifies of :on_event' do
            args = nil
            described_class.on_event do |*a|
                args = a
            end

            locator = selenium_to_locator( subject.selenium.find_element( id: 'my-div' ) )
            options = {}
            event = :click

            transition = subject.fire_event( locator, event, options )

            r, l, e, opts, browser = *args

            expect(r).to be !!transition
            expect(locator).to be l
            expect(event).to be e
            expect(options).to be opts
            expect(browser).to be subject
        end

        it 'notifies of :after_event' do
            args = nil
            described_class.after_event do |*a|
                args = a
            end

            locator = selenium_to_locator( subject.selenium.find_element( id: 'my-div' ) )
            options = {}
            event = :click

            transition = subject.fire_event( locator, event, options )

            t, l, e, opts, browser = *args

            expect(transition).to be t
            expect(locator).to be l
            expect(event).to be e
            expect(options).to be opts
            expect(browser).to be subject
        end

        it 'fires the given event' do
            subject.fire_event selenium_to_locator( subject.selenium.find_element( id: 'my-div' ) ), :click
            pages_should_have_form_with_input [subject.to_page], 'by-ajax'
        end

        it 'accepts events without the "on" prefix' do
            pages_should_not_have_form_with_input [subject.to_page], 'by-ajax'

            subject.fire_event selenium_to_locator( subject.selenium.find_element( id: 'my-div' ) ), :click
            pages_should_have_form_with_input [subject.to_page], 'by-ajax'

            subject.fire_event selenium_to_locator( subject.selenium.find_element( id: 'my-div' ) ), :click
            pages_should_have_form_with_input [subject.to_page], 'by-ajax'
        end

        it 'returns a playable transition' do
            transition = subject.fire_event selenium_to_locator( subject.selenium.find_element( id: 'my-div' ) ), :click
            pages_should_have_form_with_input [subject.to_page], 'by-ajax'

            subject.load( url ).start_capture
            pages_should_not_have_form_with_input [subject.to_page], 'by-ajax'

            transition.play subject
            pages_should_have_form_with_input [subject.to_page], 'by-ajax'
        end

        context 'when select?' do
            let(:locator) do
                selenium_to_locator( subject.selenium.find_element( id: 'my-div' ) )
            end
            let(:event) { :click }
            let(:options) { {} }

            context 'returns true' do
                it 'fires the event' do
                    args = nil
                    described_class.select do |*a|
                        args = a
                        true
                    end

                    transition = subject.fire_event( locator, event, options )

                    l, e, opts, browser = *args

                    expect(transition).to be_truthy
                    expect(locator).to be l
                    expect(event).to be e
                    expect(options).to be opts
                    expect(browser).to be subject
                end
            end

            context 'returns false' do
                it 'does not fire the event' do
                    args = nil
                    described_class.reject do |*a|
                        args = a
                        true
                    end

                    transition = subject.fire_event( locator, event, options )

                    l, e, opts, browser = *args

                    expect(transition).to be_falsey
                    expect(locator).to be l
                    expect(event).to be e
                    expect(options).to be opts
                    expect(browser).to be subject
                end
            end
        end

        context 'when new elements are introduced' do
            let(:url) { "#{root_url}/trigger_events/with_new_elements" }

            it 'sets element IDs' do
                expect(subject.selenium.find_elements( :css, 'a' )).to be_empty

                subject.fire_event selenium_to_locator( subject.selenium.find_element( id: 'my-div' ) ), :click

                expect(subject.selenium.find_elements( :css, 'a' ).first.opening_tag).to eq '<a href="#blah" data-scnr-engine-id="2073105">'
            end
        end

        context 'when new timers are introduced' do
            let(:url) { "#{root_url}/trigger_events/with_new_timers/3000" }

            it 'executes them' do
                subject.fire_event selenium_to_locator( subject.selenium.find_element( id: 'my-div' ) ), :click
                pages_should_have_form_with_input [subject.to_page], 'by-ajax'
            end
        end

        context 'when cookies are set' do
            let(:url) { root_url + '/each_element_with_events/set-cookie' }

            it 'sets them globally' do
                expect(SCNR::Engine::HTTP::Client.cookies).to be_empty

                subject.fire_event SCNR::Engine::Browser::ElementLocator.new(
                    tag_name: :button,
                    attributes: {
                        onclick: 'setCookie()'
                    }
                ), :click

                cookie = SCNR::Engine::HTTP::Client.cookies.first
                expect(cookie.name).to eq 'cookie_name'
                expect(cookie.value).to eq 'cookie value'
            end
        end

        context 'when the element is not visible' do
            it 'returns nil' do
                subject.goto "#{url}/invisible-div"
                element = selenium_to_locator( subject.selenium.find_element( id: 'invisible-div' ) )
                expect(subject.fire_event( element, :click )).to be_nil
            end
        end

        context 'and could not be located' do
            it 'returns nil' do
                element = SCNR::Engine::Browser::ElementLocator.new(
                    tag_name:   'body',
                    attributes: { 'id' => 'blahblah' }
                )

                allow(element).to receive(:locate){ raise Selenium::WebDriver::Error::WebDriverError }
                expect(subject.fire_event( element, :click )).to be_nil
            end
        end

        context 'when the trigger fails with' do
            let(:element) { selenium_to_locator( subject.selenium.find_element( id: 'my-div' ) ) }

            context 'Selenium::WebDriver::Error::WebDriverError' do
                it 'returns nil' do
                    allow(subject.engine).to receive(:wait_for_pending_requests) do
                        raise Selenium::WebDriver::Error::WebDriverError
                    end

                    expect(subject.fire_event( element, :click )).to be_nil
                end
            end
        end

        context 'form' do
            context ':submit' do
                let(:url) { "#{root_url}/fire_event/form/onsubmit" }

                def element
                    selenium_to_locator subject.selenium.find_element(:tag_name, :form)
                end

                context 'when there is a submit button' do
                    let(:url) { "#{root_url}/fire_event/form/submit_button" }
                    let(:inputs) do
                        {
                            name:  'The Dude',
                            email: 'the.dude@abides.com'
                        }
                    end

                    it 'clicks it' do
                        subject.fire_event element, :submit, inputs: inputs

                        expect(subject.watir.div( id: 'container-name' ).text).to eq( inputs[:name] )
                        expect(subject.watir.div( id: 'container-email' ).text).to eq( inputs[:email] )
                    end
                end

                context 'when there is a submit input' do
                    let(:url) { "#{root_url}/fire_event/form/submit_input" }
                    let(:inputs) do
                        {
                            name:  'The Dude',
                            email: 'the.dude@abides.com'
                        }
                    end

                    it 'clicks it' do
                        subject.fire_event element, :submit, inputs: inputs

                        expect(subject.watir.div( id: 'container-name' ).text).to eq( inputs[:name] )
                        expect(subject.watir.div( id: 'container-email' ).text).to eq( inputs[:email] )
                    end
                end

                context 'when there is no submit button or input' do
                    let(:url) { "#{root_url}/fire_event/form/onsubmit" }
                    let(:inputs) do
                        {
                            name:  'The Dude',
                            email: 'the.dude@abides.com'
                        }
                    end

                    it 'triggers the submit event' do
                        subject.fire_event element, :submit, inputs: inputs

                        expect(subject.watir.div( id: 'container-name' ).text).to eq( inputs[:name] )
                        expect(subject.watir.div( id: 'container-email' ).text).to eq( inputs[:email] )
                    end
                end

                context 'when option' do
                    describe ':inputs' do

                        context 'is given' do
                            let(:inputs) do
                                {
                                    name:  'The Dude',
                                    email: 'the.dude@abides.com'
                                }
                            end

                            before(:each) do
                                subject.fire_event element, :submit, inputs: inputs
                            end

                            it 'fills in its inputs with the given values' do
                                expect(subject.watir.div( id: 'container-name' ).text).to eq( inputs[:name] )
                                expect(subject.watir.div( id: 'container-email' ).text).to eq( inputs[:email] )
                            end

                            it 'returns a playable transition' do
                                subject.load url

                                transition = subject.fire_event element, :submit, inputs: inputs

                                subject.load url

                                expect(subject.watir.div( id: 'container-name' ).text).to be_empty
                                expect(subject.watir.div( id: 'container-email' ).text).to be_empty

                                transition.play subject

                                expect(subject.watir.div( id: 'container-name' ).text).to eq(  inputs[:name] )
                                expect(subject.watir.div( id: 'container-email' ).text).to eq( inputs[:email] )
                            end

                            context 'when the inputs contains non-UTF8 data' do
                                context 'is given' do
                                    let(:inputs) do
                                        {
                                            name:  "The Dude \xC7",
                                            email: "the.dude@abides.com \xC7"
                                        }
                                    end
                                end

                                it 'recodes them' do
                                    expect(subject.watir.div( id: 'container-name' ).text).to eq( inputs[:name].recode )
                                    expect(subject.watir.div( id: 'container-email' ).text).to eq( inputs[:email].recode )
                                end
                            end

                            context 'when one of those inputs is a' do
                                context 'select' do
                                    let(:url) { "#{root_url}/fire_event/form/select" }

                                    it 'selects it' do
                                        expect(subject.watir.div( id: 'container-name' ).text).to eq( inputs[:name] )
                                        expect(subject.watir.div( id: 'container-email' ).text).to eq( inputs[:email] )
                                    end
                                end
                            end

                            context 'but has missing values' do
                                let(:inputs) do
                                    { name:  'The Dude' }
                                end

                                it 'leaves those empty' do
                                    expect(subject.watir.div( id: 'container-name' ).text).to eq( inputs[:name] )
                                    expect(subject.watir.div( id: 'container-email' ).text).to be_empty
                                end

                                it 'returns a playable transition' do
                                    subject.load url
                                    transition = subject.fire_event element, :submit, inputs: inputs

                                    subject.load url

                                    expect(subject.watir.div( id: 'container-name' ).text).to be_empty
                                    expect(subject.watir.div( id: 'container-email' ).text).to be_empty

                                    transition.play subject

                                    expect(subject.watir.div( id: 'container-name' ).text).to eq( inputs[:name] )
                                    expect(subject.watir.div( id: 'container-email' ).text).to be_empty
                                end
                            end

                            context 'and is empty' do
                                let(:inputs) do
                                    {}
                                end

                                it 'fills in empty values' do
                                    expect(subject.watir.div( id: 'container-name' ).text).to be_empty
                                    expect(subject.watir.div( id: 'container-email' ).text).to be_empty
                                end

                                it 'returns a playable transition' do
                                    subject.load url
                                    transition = subject.fire_event element, :submit, inputs: inputs

                                    subject.load url

                                    expect(subject.watir.div( id: 'container-name' ).text).to be_empty
                                    expect(subject.watir.div( id: 'container-email' ).text).to be_empty

                                    transition.play subject

                                    expect(subject.watir.div( id: 'container-name' ).text).to be_empty
                                    expect(subject.watir.div( id: 'container-email' ).text).to be_empty
                                end
                            end

                            context 'and has disabled inputs' do
                                let(:url) { "#{root_url}/fire_event/form/disabled_inputs" }

                                it 'is skips those inputs' do
                                    expect(subject.watir.div( id: 'container-name' ).text).to eq( inputs[:name] )
                                    expect(subject.watir.div( id: 'container-email' ).text).to be_empty
                                end
                            end
                        end

                        context 'is not given' do
                            it 'fills in its inputs with sample values' do
                                subject.load url
                                subject.fire_event element, :submit

                                expect(subject.watir.div( id: 'container-name' ).text).to eq(
                                    SCNR::Engine::Options.input.value_for_name( 'name' )
                                )
                                expect(subject.watir.div( id: 'container-email' ).text).to eq(
                                    SCNR::Engine::Options.input.value_for_name( 'email' )
                                )
                            end

                            it 'returns a playable transition' do
                                subject.load url
                                transition = subject.fire_event element, :submit

                                subject.load url

                                expect(subject.watir.div( id: 'container-name' ).text).to be_empty
                                expect(subject.watir.div( id: 'container-email' ).text).to be_empty

                                transition.play subject

                                expect(subject.watir.div( id: 'container-name' ).text).to eq(
                                    SCNR::Engine::Options.input.value_for_name( 'name' )
                                )
                                expect(subject.watir.div( id: 'container-email' ).text).to eq(
                                    SCNR::Engine::Options.input.value_for_name( 'email' )
                                )
                            end

                            context 'and has disabled inputs' do
                                let(:url) { "#{root_url}/fire_event/form/disabled_inputs" }

                                it 'is skips those inputs' do
                                    subject.fire_event element, :submit

                                    expect(subject.watir.div( id: 'container-name' ).text).to eq(
                                        SCNR::Engine::Options.input.value_for_name( 'name' )
                                    )
                                    expect(subject.watir.div( id: 'container-email' ).text).to be_empty
                                end
                            end
                        end
                    end
                end
            end

            context ':fill' do
                before(:each) do
                    subject.load url
                end

                let(:url) { "#{root_url}/fire_event/form/onsubmit" }
                let(:inputs) do
                    {
                        name:  "The Dude",
                        email: "the.dude@abides.com"
                    }
                end

                def element
                    selenium_to_locator subject.selenium.find_element(:tag_name, :form)
                end

                it 'fills in the form inputs' do
                    subject.fire_event element, :fill, inputs: inputs

                    expect(subject.watir.textarea( name: 'name' ).value).to eq( inputs[:name] )
                    expect(subject.watir.input( id: 'email' ).value).to eq( inputs[:email] )

                    expect(subject.watir.div( id: 'container-name' ).text).to be_empty
                    expect(subject.watir.div( id: 'container-email' ).text).to be_empty
                end

                it 'returns a playable transition' do
                    subject.load url
                    transition = subject.fire_event element, :fill, inputs: inputs

                    subject.load url

                    expect(subject.watir.textarea( name: 'name' ).value).to be_empty
                    expect(subject.watir.input( id: 'email' ).value).to be_empty

                    transition.play subject

                    expect(subject.watir.textarea( name: 'name' ).value).to eq( inputs[:name] )
                    expect(subject.watir.input( id: 'email' ).value).to eq( inputs[:email] )
                end
            end

            context 'image button' do
                context ':click' do
                    before( :each ) { subject.start_capture }
                    let(:url) { "#{root_url}fire_event/form/image-input" }
                    let(:other) { SCNR::Engine::Browser.new.start_capture }

                    def element
                        selenium_to_locator subject.selenium.find_element( :xpath, '//input[@type="image"]')
                    end

                    it 'submits the form with x, y coordinates' do
                        subject.load( url )
                        subject.fire_event element, :click

                        pages_should_have_form_with_input subject.captured_pages, 'myImageButton.x'
                        pages_should_have_form_with_input subject.captured_pages, 'myImageButton.y'
                    end

                    it 'returns a playable transition' do
                        subject.load( url )
                        transition = subject.fire_event element, :click

                        captured_pages = subject.flush_pages
                        pages_should_have_form_with_input captured_pages, 'myImageButton.x'
                        pages_should_have_form_with_input captured_pages, 'myImageButton.y'

                        other.load( url, take_snapshot: true )
                        expect(other.flush_pages.size).to eq(1)

                        transition.play other
                        captured_pages = other.flush_pages
                        pages_should_have_form_with_input captured_pages, 'myImageButton.x'
                        pages_should_have_form_with_input captured_pages, 'myImageButton.y'
                    end
                end
            end
        end

        context 'input' do
            [
                :onselect,
                :onchange,
                :onfocus,
                :onblur,
                :onkeydown,
                :onkeypress,
                :onkeyup,
                :oninput
            ].each do |event|
                calculate_expectation = proc do |string|
                    string
                end

                context event.to_s do
                    let( :url ) { "#{root_url}/fire_event/input/#{event}" }

                    context 'when option' do
                        describe ':inputs' do
                            def element
                                selenium_to_locator subject.selenium.find_element(:tag_name, :input)
                            end

                            context 'is given' do
                                let(:value) do
                                    'The Dude'
                                end

                                before(:each) do
                                    subject.fire_event element, event, value: value
                                end

                                it 'fills in its inputs with the given values' do
                                    expect(subject.watir.div( id: 'container' ).text).to eq(
                                        calculate_expectation.call( value )
                                    )
                                end

                                it 'returns a playable transition' do
                                    subject.load url
                                    transition = subject.fire_event element, event, value: value

                                    subject.load url
                                    expect(subject.watir.div( id: 'container' ).text).to be_empty

                                    transition.play subject
                                    expect(subject.watir.div( id: 'container' ).text).to eq(
                                        calculate_expectation.call( value )
                                    )
                                end

                                context 'and is empty' do
                                    let(:value) do
                                        ''
                                    end

                                    it 'fills in empty values' do
                                        expect(subject.watir.div( id: 'container' ).text).to be_empty
                                    end

                                    it 'returns a playable transition' do
                                        subject.load url
                                        transition = subject.fire_event element, event, value: value

                                        subject.load url
                                        expect(subject.watir.div( id: 'container' ).text).to be_empty

                                        transition.play subject
                                        expect(subject.watir.div( id: 'container' ).text).to be_empty
                                    end
                                end
                            end

                            context 'is not given' do
                                it 'fills in a sample value' do
                                    subject.fire_event element, event

                                    expect(subject.watir.div( id: 'container' ).text).to eq(
                                        calculate_expectation.call( SCNR::Engine::Options.input.value_for_name( 'name' ) )
                                    )
                                end

                                it 'returns a playable transition' do
                                    subject.load url
                                    transition = subject.fire_event element, event

                                    subject.load url
                                    expect(subject.watir.div( id: 'container' ).text).to be_empty

                                    transition.play subject
                                    expect(subject.watir.div( id: 'container' ).text).to eq(
                                        calculate_expectation.call( SCNR::Engine::Options.input.value_for_name( 'name' ) )
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end
    end

end
