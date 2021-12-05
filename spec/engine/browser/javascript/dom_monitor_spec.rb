require 'spec_helper'

describe SCNR::Engine::Browser::Javascript::DOMMonitor do

    def load( path )
        browser.load "#{url}/#{path}"
    end

    before( :each ) do
        browser.load url
    end

    let(:root_url) { SCNR::Engine::Utilities.normalize_url( web_server_url_for( :dom_monitor ) ) }
    let(:url) { root_url }
    let(:browser) { SCNR::Engine::Browser.new }
    let(:javascript) { browser.javascript }
    subject { described_class.new( javascript ) }

    describe '#class' do
        it "returns #{described_class}" do
            expect(subject.class).to eq(described_class)
        end
    end

    describe '#initialized' do
        it 'returns true' do
            expect(subject.initialized).to be_truthy
        end
    end

    describe '#timeouts' do
        it 'keeps track of setTimeout() timers' do
            load '/timeouts'
            sleep 2

            expect(subject.timeouts).to eq([
             [
               "function( name, value ){\n            document.cookie = name + \"=post-\" + value\n        }",
               1000, 'timeout1', 1000
             ],
             [
               "function( name, value ){\n            document.cookie = name + \"=post-\" + value\n        }",
               1500, 'timeout2', 1500
             ],
             [
               "function( name, value ){\n            document.cookie = name + \"=post-\" + value\n        }",
               2000, 'timeout3', 2000
             ]
            ])

            expect(javascript.max_timer).to eq(2000)
            expect(browser.cookies.size).to eq(4)
            expect(browser.cookies.map { |c| c.to_s }.sort).to eq([
             'timeout3=post-2000',
             'timeout2=post-1500',
             'timeout1=post-1000',
             'timeout=pre'
            ].sort)
        end
    end

    it 'adds _scnr_engine_events property to elements holding the tracked events' do
        load '/elements_with_events/listeners'

        events = javascript.run( "return document.getElementById('my-button')._scnr_engine_events")
        events.each do |_, js|
            format_js!( js )
        end

        expect(events).to eq([
            [
                'click',
                format_js!( 'function ( my_button_click ){}' )
            ],
            [
                'click',
                format_js!( 'function ( my_button_click2 ){}' )
            ],
            [
                'onmouseover',
                format_js!( 'function ( my_button_onmouseover ){}' )
            ]
        ])

        events = javascript.run( "return document.getElementById('my-button2')._scnr_engine_events")
        events.each do |_, js|
            format_js!( js )
        end
        expect(events).to eq([
            [
                'click',
                format_js!( 'function ( my_button2_click ){}' )
            ]
        ])

        expect(javascript.run( "return document.getElementById('my-button3')._scnr_engine_events")).to be_nil
    end

    describe '#summary' do
        it 'returns a string digest of the current DOM tree' do
            load '/digest'
            expect(subject.summary).to eq('<HTML><HEAD><BODY onload=void();><DIV id=my-id-div><DIV class=my-class-div><STRONG><EM><I><B><STRONG><SCRIPT><A href=#stuff>')
        end

        it 'does not include <p> elements' do
            load '/digest/p'
            expect(subject.summary).to eq('<HTML><HEAD><BODY><STRONG>')
        end

        it "does not include #{SCNR::Engine::Browser::ElementLocator::ENGINE_ID} attributes" do
            load "/digest/#{SCNR::Engine::Browser::ElementLocator::ENGINE_ID}"
            expect(subject.summary).to eq('<HTML><HEAD><BODY><DIV id=my-id-div><DIV class=my-class-div>')
        end
    end

    describe '#digest' do
        it 'returns an integer digest of the current DOM tree' do
            load '/digest'
            expect(subject.digest).to eq(1752637387)
        end

        it 'does not include <p> elements' do
            load '/digest/p'
            expect(subject.digest).to eq(616351428)
        end

        it "does not include #{SCNR::Engine::Browser::ElementLocator::ENGINE_ID} attributes" do
            load "/digest/#{SCNR::Engine::Browser::ElementLocator::ENGINE_ID}"
            expect(subject.digest).to eq(-1681103135)
        end
    end

    describe '#elements_with_events' do
        it 'skips non visible elements' do
            load '/elements_with_events/with-hidden'

            expect(format_js_elements_with_events!( subject.elements_with_events )).to eq(
                format_js_elements_with_events!([
                    {
                        'tag_name' => 'button',
                        'events' => {
                            'click' =>  [
                                'function ( my_button_click ){}',
                                'handler_1()'
                            ]
                        },
                        'attributes' => {
                            'onclick' => 'handler_1()',
                            'id' => 'my-button'
                        }
                    }
                ])
            )
        end

        context "when #{SCNR::Engine::OptionGroups::Scope}#dom_event_inheritance_limit has been set" do
            it 'limits the amount of elements that inherit parent events'
        end

        context 'when given a maximum amount of events' do
            it 'limits the amount of elements returned' do
                load '/elements_with_events/whitelist'
                ewe = format_js_elements_with_events!( subject.elements_with_events( 0, 100, 2 ) )
                expect(ewe).to eq(format_js_elements_with_events!(
                  [
                      {
                          'attributes' => { 'id' => 'parent' },
                          'events'     => { 'click' => ['function(parent_click){}'] },
                          'tag_name'   => 'div'
                      },
                      {
                          'attributes' => { 'id' => 'parent-button' },
                          'events'     =>
                              { 'click' => [
                                  'function(parent_click){}',
                                  'function(window_click){}',
                                  'function(document_click){}'] },
                          'tag_name'   => 'button'
                      }
                  ]
              ))
            end
        end

        context 'when given a whitelist of tag names' do
            it 'only returns those types of elements' do
                load '/elements_with_events/whitelist'

                ewe = format_js_elements_with_events!( subject.elements_with_events( 0, 100, nil, ['span'] ) )
                expect(ewe).to eq(format_js_elements_with_events!([
                    {
                        'tag_name'   => 'span',
                        'events'     =>
                            {
                                'click' => [
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

        context 'when it has a dot delimited custom event' do
            it 'retains the first part' do
                load '/elements_with_events/custom-dot-delimited'

                expect(format_js_elements_with_events!( subject.elements_with_events )).to eq(
                    format_js_elements_with_events!([
                        {
                            "tag_name"   => "button",
                            "events"     => {
                                "click"=> [
                                    format_js!( "function ( e ) {\n\t\t\t\t// Discard the second event of a jQuery.event.trigger() and\n\t\t\t\t// when an event is called after a page has unloaded\n\t\t\t\treturn typeof jQuery !== core_strundefined && (!e || jQuery.event.triggered !== e.type) ?\n\t\t\t\t\tjQuery.event.dispatch.apply( eventHandle.elem, arguments ) :\n\t\t\t\t\tundefined;\n\t\t\t}" )
                                ]
                            },
                            "attributes" => {
                                "id" => "my-button"
                            }
                        }
                    ])
                )
            end
        end

        context 'when using' do
            context 'event attributes' do
                it 'returns information about all DOM elements along with their events' do
                    load '/elements_with_events/attributes'

                    expect(format_js_elements_with_events!( subject.elements_with_events )).to eq(
                        format_js_elements_with_events!( [
                            {
                                'tag_name'   => 'button',
                                'events'     => {
                                    'click' => ['handler_1()']
                                },
                                'attributes' => { 'onclick' => 'handler_1()', 'id' => 'my-button' }
                            },
                            {
                                'tag_name'   => 'button',
                                'events'     => {
                                    'click' => ['handler_2()']
                                },
                                'attributes' => { 'onclick' => 'handler_2()', 'id' => 'my-button2' }
                             },
                             {
                                 'tag_name' => 'button',
                                 'events'     => {
                                     'click' => ['handler_3()']
                                 },
                                 'attributes' => { 'onclick' => 'handler_3()', 'id' => 'my-button3' }
                             }
                        ])
                    )
                end
            end

            context 'event listeners' do
                it 'returns information about all DOM elements along with their events' do
                    load '/elements_with_events/listeners'

                    expect(format_js_elements_with_events!( subject.elements_with_events )).to eq(
                        format_js_elements_with_events!([
                            {
                                'tag_name'   => 'button',
                                'events'     => {
                                    'click' => [
                                        'function ( my_button_click ){}',
                                        'function ( my_button_click2 ){}'
                                    ],
                                    'mouseover' => ['function ( my_button_onmouseover ){}']
                                },
                                'attributes' => { 'id' => 'my-button' }
                            },
                            {
                                'tag_name'   => 'button',
                                'events'     => {
                                    'click' => ['function ( my_button2_click ){}']
                                },
                                'attributes' => { 'id' => 'my-button2' }
                            }
                        ])
                    )
                end
            end

            context 'inherited events' do
                it 'returns information about all DOM elements along with their events' do
                    load 'elements_with_events/inherited'

                    expect(format_js_elements_with_events!( subject.elements_with_events )).to eq(
                        format_js_elements_with_events!( [
                            {
                               "tag_name"   => "div",
                               "events"     => {
                                   "click" => [
                                       "function ( parent_click ){}"
                                   ]
                               },
                               "attributes" => { "id" => "parent" } },
                            {
                               "tag_name"   => "button",
                               "events"     => {
                                   "click" => [
                                       "function ( parent_click ){}",
                                       "function ( window_click ){}",
                                       "function ( document_click ){}"
                                   ]
                               },
                               "attributes" => { "id" => "parent-button" }
                            },
                            {
                               "tag_name"   => "div",
                               "events"     => {
                                   "click" => ["function ( child_click ){}"]
                               },
                               "attributes" => { "id" => "child" }
                            },
                            {
                               "tag_name"   => "button",
                               "events"     => {
                                   "click" => [
                                       "function ( parent_click ){}",
                                       "function ( child_click ){}",
                                       "function ( window_click ){}",
                                       "function ( document_click ){}"
                                   ]
                               },
                               "attributes" => { "id" => "child-button" }
                            }
                        ])
                    )
                end
            end
        end
    end

    describe '#event_digest' do
        let(:root_url) { SCNR::Engine::Utilities.normalize_url( web_server_url_for( :browser ) ) }
        let(:url) { root_url + '/trigger_events' }
        let(:empty_event_digest_url) { url + '/event_digest/default' }
        let(:empty_event_digest) do
            browser.load( empty_event_digest_url )
            subject.event_digest
        end
        let(:event_digest) do
            browser.load( url )
            subject.event_digest
        end

        it 'returns a DOM digest' do
            expect(event_digest).to eq(subject.event_digest)
        end

        context 'when there are new cookies' do
            let(:url) { root_url + '/each_element_with_events/set-cookie' }

            it 'takes them into account' do
                ed = event_digest

                browser.fire_event SCNR::Engine::Browser::ElementLocator.new(
                    tag_name: :button,
                    attributes: {
                        onclick: 'setCookie()'
                    }
                ), :click

                expect(subject.event_digest).not_to eq(ed)
            end
        end

        context ':a' do
            context 'and the href is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { root_url + '/each_element_with_events/a/href/javascript' }

                    it 'takes it into account' do
                        expect(event_digest).not_to eq(empty_event_digest)
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { root_url + '/each_element_with_events/a/href/regular' }

                    it 'takes it into account' do
                        expect(event_digest).not_to eq(empty_event_digest)
                    end
                end
            end

            context 'and the href is empty' do
                let(:url) { root_url + '/each_element_with_events/a/href/empty' }

                it 'takes it into account' do
                    expect(event_digest).not_to eq(empty_event_digest)
                end
            end
        end

        context ':form' do
            let(:empty_event_digest_url) { root_url + '/event_digest/form/default' }

            context ':input' do
                context 'of type "image"' do
                    let(:url) { root_url + '/each_element_with_events/form/input/image' }

                    it 'takes it into account' do
                        expect(event_digest).not_to eq(empty_event_digest)
                    end
                end
            end

            context 'and the action is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { root_url + '/each_element_with_events/form/action/javascript' }

                    it 'takes it into account' do
                        expect(event_digest).not_to eq(empty_event_digest)
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { root_url + '/each_element_with_events/form/action/regular' }

                    it 'takes it into account' do
                        expect(event_digest).not_to eq(empty_event_digest)
                    end
                end
            end
        end
    end
end
