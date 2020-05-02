require 'spec_helper'

describe SCNR::Engine::Browser::Javascript do
    include_examples 'javascript'

    describe '#dom_monitor' do
        it 'provides access to the DOMMonitor javascript interface' do
            browser.load "#{taint_tracer_url}/debug"
            expect(subject.dom_monitor.js_object).to end_with 'DOMMonitor'
        end
    end

    describe '#taint_tracer' do
        it 'provides access to the TaintTracer javascript interface' do
            browser.load "#{taint_tracer_url}/debug"
            expect(subject.taint_tracer.js_object).to end_with 'TaintTracer'
        end
    end

    describe '#each_dom_element_with_events' do
        it "enforces #{SCNR::Engine::OptionGroups}#dom_event_limit" do
            browser.load dom_monitor_url + 'elements_with_events/whitelist'

            SCNR::Engine::Options.scope.dom_event_limit = 2

            e = []
            subject.each_dom_element_with_events do |element|
                e << element
            end

            expect(format_js_elements_with_events!( e )).to eq(format_js_elements_with_events!([
                   {
                       "attributes" => { "id" => "parent"
                       },
                       "events"     => {
                           :click => [
                               "function ( parent_click ){}"
                           ]
                       },
                       "tag_name"   => "div"
                   },
                   {
                       "attributes" => { "id" => "parent-button" },
                       "events"     =>
                           {
                               :click =>
                                   [
                                       "function ( parent_click ){}",
                                       "function ( window_click ){}",
                                       "function ( document_click ){}"
                                   ]
                           },
                       "tag_name"   => "button"
                   }
               ]
           ))
        end

        context 'when given a whitelist of tag names' do
            it 'only returns those types of elements' do
                browser.load dom_monitor_url + 'elements_with_events/whitelist'

                e = []
                subject.each_dom_element_with_events ['span'] do |element|
                    e << element
                end

                expect(format_js_elements_with_events!( e )).to eq(format_js_elements_with_events!([
                    {
                     'tag_name'   => 'span',
                     'events'     =>
                         {
                             click: [
                                 'function ( parent_click ){}',
                                 'function ( child_click ){}',
                                 'function ( window_click ){}',
                                 'function ( document_click ){}'
                             ]
                         },
                     'attributes' => { 'id' => 'child-span' }
                    }
                ]))
            end
        end

        context 'when using event attributes' do
            it 'returns information about all DOM elements along with their events' do
                browser.load dom_monitor_url + 'elements_with_events/attributes'

                e = []
                subject.each_dom_element_with_events do |element|
                    e << element
                end

                expect(format_js_elements_with_events!( e )).to eq(
                    format_js_elements_with_events!([
                        {
                            'tag_name'   => 'button',
                            'events'     => {
                                click: [ 'handler_1()' ]
                            },
                            'attributes' => { 'onclick' => 'handler_1()', 'id' => 'my-button' }
                        },
                        {
                            'tag_name'   => 'button',
                            'events'     => {
                                click: ['handler_2()']
                            },
                            'attributes' => { 'onclick' => 'handler_2()', 'id' => 'my-button2' }
                        },
                        {
                            'tag_name'   => 'button',
                            'events'     => {
                                click: ['handler_3()']
                            },
                            'attributes' => { 'onclick' => 'handler_3()', 'id' => 'my-button3' }
                        }
                    ])
                )
            end

            context 'with inappropriate events for the element' do
                it 'ignores them' do
                    browser.load dom_monitor_url + 'elements_with_events/attributes/inappropriate'

                    e = []
                    subject.each_dom_element_with_events do |element|
                        e << element
                    end

                    expect(e).to be_empty
                end
            end
        end

        context 'when using event listeners' do
            it 'returns information about all DOM elements along with their events' do
                browser.load dom_monitor_url + 'elements_with_events/listeners'

                e = []
                subject.each_dom_element_with_events do |element|
                    e << element
                end

                expect(format_js_elements_with_events!( e )).to eq(
                    format_js_elements_with_events!([
                        {
                            'tag_name'   => 'button',
                            'events'     => {
                                click: ['function ( my_button_click ){}', 'function ( my_button_click2 ){}'],
                                mouseover: ['function ( my_button_onmouseover ){}']
                            },
                            'attributes' => { 'id' => 'my-button' } },
                        {
                            'tag_name'   => 'button',
                            'events'     => {
                                click: ['function ( my_button2_click ){}']
                            },
                            'attributes' => { 'id' => 'my-button2' } }
                    ])
                )
            end

            it 'does not include custom events' do
                browser.load dom_monitor_url + 'elements_with_events/listeners/custom'

                e = []
                subject.each_dom_element_with_events do |element|
                    e << element
                end

                expect(e).to be_empty
            end

            context 'with inappropriate events for the element' do
                it 'ignores them' do
                    browser.load dom_monitor_url + 'elements_with_events/listeners/inappropriate'

                    e = []
                    subject.each_dom_element_with_events do |element|
                        e << element
                    end

                    expect(e).to be_empty
                end
            end
        end
    end


    describe '#run' do
        it 'executes the given script under the browser\'s context' do
            browser.load dom_monitor_url
            expect(Nokogiri::HTML(browser.real_source).to_s).to eq(
                Nokogiri::HTML(subject.run( 'return document.documentElement.outerHTML' ) ).to_s
            )
        end
    end

    describe '#run_without_elements' do
        it 'executes the given script and unwraps Watir elements' do
            browser.load dom_monitor_url
            source = Nokogiri::HTML(browser.real_source).to_s

            expect(source).to eq(
                Nokogiri::HTML(subject.run_without_elements( 'return document.documentElement' ) ).to_s
            )

            expect(source).to eq(
                Nokogiri::HTML(subject.run_without_elements( 'return [document.documentElement]' ).first ).to_s
            )

            expect(source).to eq(
                Nokogiri::HTML(subject.run_without_elements( 'return { html: document.documentElement }' )['html'] ).to_s
            )
        end
    end
end
