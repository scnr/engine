require 'spec_helper'

describe SCNR::Engine::Browser::Parts::Snapshots do
    include_examples 'browser'

    describe '#initialize' do
        describe ':parse_profile' do
            context 'given' do
                let(:profile) { SCNR::Engine::Browser::ParseProfile.new }
                let(:options) { { parse_profile: profile } }

                it 'sets #parse_profile' do
                    expect(subject.parse_profile).to be profile
                end
            end

            context 'by default' do
                it 'initializes a default one' do
                    expect(subject.parse_profile).to eq SCNR::Engine::Browser::ParseProfile.new
                end
            end
        end

        describe ':store_pages' do
            describe 'default' do
                it 'stores snapshot pages' do
                    expect(subject.load( url + '/explore', take_snapshot: true ).flush_pages).to be_any
                end

                it 'stores captured pages' do
                    subject.start_capture
                    expect(subject.load( url + '/with-ajax', take_snapshot: true ).flush_pages).to be_any
                end
            end

            describe 'true' do
                let(:options) { { store_pages: true } }

                it 'stores snapshot pages' do
                    expect(subject.load( url + '/explore', take_snapshot: true ).trigger_events.flush_pages).to be_any
                end

                it 'stores captured pages' do
                    subject.start_capture
                    expect(subject.load( url + '/with-ajax', take_snapshot: true ).flush_pages).to be_any
                end
            end

            describe 'false' do
                let(:options) { { store_pages: false } }

                it 'stores snapshot pages' do
                    expect(subject.load( url + '/explore', take_snapshot: true ).trigger_events.flush_pages).to be_empty
                end

                it 'stores captured pages' do
                    subject.start_capture
                    expect(subject.load( url + '/with-ajax', take_snapshot: true ).flush_pages).to be_empty
                end
            end
        end
    end

    describe '#capture_snapshot' do
        let(:sink_url) do
            "#{url}script_sink?input=#{subject.javascript.log_execution_flow_sink_stub(1)}"
        end
        let(:ajax_url) do
            "#{url}with-ajax"
        end
        let(:captured) { subject.capture_snapshot }

        context 'when a snapshot has not been previously seen' do
            before :each do
                subject.load( url + '/with-ajax' )
            end

            it 'calls #on_new_page callbacks' do
                received = []
                subject.on_new_page do |page|
                    received << page
                end

                expect(captured).to eq(received)
            end

            context '#store_pages?' do
                context 'true' do
                    let(:options) { { store_pages: true } }

                    it 'stores it in #page_snapshots' do
                        captured = subject.capture_snapshot

                        expect(subject.page_snapshots).to eq(captured)
                    end

                    it 'returns it' do
                        expect(captured.size).to eq(1)
                        expect(captured.first).to eq(subject.to_page)
                    end
                end

                context 'false' do
                    let(:options) { { store_pages: false } }

                    it 'does not store it' do
                        subject.capture_snapshot

                        expect(subject.page_snapshots).to be_empty
                    end

                    it 'returns an empty array' do
                        expect(captured).to be_empty
                    end
                end
            end
        end

        context 'when a snapshot has already been seen' do
            before :each do
                subject.load( url + '/with-ajax' )
            end

            it 'ignores it' do
                expect(subject.capture_snapshot).to be_any
                expect(subject.capture_snapshot).to be_empty
            end
        end

        context 'when a snapshot has sink data' do
            before :each do
                subject.load sink_url
            end

            it 'calls #on_new_page_with_sink callbacks' do
                sinks = []
                subject.on_new_page_with_sink do |page|
                    sinks << page.dom.execution_flow_sinks
                end

                subject.capture_snapshot

                expect(sinks.size).to eq(1)
            end

            context 'and has not already been seen' do
                it 'calls #on_new_page_with_sink callbacks' do
                    sinks = []
                    subject.on_new_page_with_sink do |page|
                        sinks << page.dom.execution_flow_sinks
                    end

                    subject.capture_snapshot
                    subject.capture_snapshot

                    expect(sinks.size).to eq(2)
                end
            end

            context '#store_pages?' do
                context 'true' do
                    let(:options) { { store_pages: true } }

                    it 'stores it in #page_snapshots_with_sinks' do
                        subject.capture_snapshot
                        expect(subject.page_snapshots_with_sinks).to be_any
                    end
                end

                context 'false' do
                    let(:options) { { store_pages: false } }

                    it 'does not store it in #page_snapshots_with_sinks' do
                        subject.capture_snapshot
                        expect(subject.page_snapshots_with_sinks).to be_empty
                    end
                end
            end
        end

        context 'when a transition has been given' do
            before :each do
                subject.load( ajax_url )
            end

            it 'pushes it to the existing transitions' do
                transition = SCNR::Engine::Page::DOM::Transition.new(
                    :page, :load
                )
                captured = subject.capture_snapshot( transition )

                expect(captured.first.dom.transitions).to include transition
            end
        end

        context 'when a page has the same transitions but different states' do
            it 'only captures the first state' do
                subject.load( "#{url}/ever-changing-dom", take_snapshot: false )
                expect(subject.capture_snapshot).to be_any

                subject.load( "#{url}/ever-changing-dom", take_snapshot: false )
                expect(subject.capture_snapshot).to be_empty
            end
        end

        context 'when there are multiple windows open' do
            it 'captures snapshots from all windows' do
                u = "#{url}open-new-window"

                subject.load u

                expect(subject.capture_snapshot.map(&:url).sort).to eq(
                    [u, "#{url}with-ajax"].sort
                )
            end
        end

        context 'when an error occurs' do
            it 'ignores it' do
                allow(subject).to receive(:to_page) { raise }
                expect(subject.capture_snapshot( blah: :stuff )).to be_empty
            end
        end
    end

    describe '#flush_page_snapshots_with_sinks' do
        it 'returns pages with data-flow sink data' do
            subject.load "#{url}/lots_of_sinks?input=#{subject.javascript.log_data_flow_sink_stub( function: { name: 'blah' } )}"
            subject.explore_and_flush
            expect(subject.page_snapshots_with_sinks.map(&:dom).map(&:data_flow_sinks)).to eq(
                                                                                                subject.flush_page_snapshots_with_sinks.map(&:dom).map(&:data_flow_sinks)
                                                                                            )
        end

        it 'returns pages with execution-flow sink data' do
            subject.load "#{url}/lots_of_sinks?input=#{subject.javascript.log_execution_flow_sink_stub( function: { name: 'blah' } )}"
            subject.explore_and_flush
            expect(subject.page_snapshots_with_sinks.map(&:dom).map(&:execution_flow_sinks)).to eq(
                                                                                                     subject.flush_page_snapshots_with_sinks.map(&:dom).map(&:execution_flow_sinks)
                                                                                                 )
        end

        it 'empties the data-flow sink page buffer' do
            subject.load "#{url}/lots_of_sinks?input=#{subject.javascript.log_data_flow_sink_stub( function: { name: 'blah' } )}"
            subject.explore_and_flush
            subject.flush_page_snapshots_with_sinks.map(&:dom).map(&:data_flow_sinks)
            expect(subject.page_snapshots_with_sinks).to be_empty
        end

        it 'empties the execution-flow sink page buffer' do
            subject.load "#{url}/lots_of_sinks?input=#{subject.javascript.log_execution_flow_sink_stub( function: { name: 'blah' } )}"
            subject.explore_and_flush
            subject.flush_page_snapshots_with_sinks.map(&:dom).map(&:execution_flow_sinks)
            expect(subject.page_snapshots_with_sinks).to be_empty
        end
    end

    describe '#on_new_page_with_sink' do
        it 'assigns blocks to handle each page with execution-flow sink data' do
            subject.load "#{url}/lots_of_sinks?input=#{subject.javascript.log_execution_flow_sink_stub( function: { name: 'blah' } )}"

            sinks = []
            subject.on_new_page_with_sink do |page|
                sinks << page.dom.execution_flow_sinks
            end

            subject.explore_and_flush

            expect(sinks.size).to eq(2)
            expect(sinks).to eq(subject.page_snapshots_with_sinks.map(&:dom).
                map(&:execution_flow_sinks))
        end

        it 'assigns blocks to handle each page with data-flow sink data' do
            subject.javascript.taint = 'taint'
            subject.load "#{url}/lots_of_sinks?input=#{subject.javascript.log_data_flow_sink_stub( subject.javascript.taint, function: { name: 'blah' } )}"

            sinks = []
            subject.on_new_page_with_sink do |page|
                sinks << page.dom.data_flow_sinks
            end

            subject.explore_and_flush

            expect(sinks.size).to eq(2)
            expect(sinks).to eq(subject.page_snapshots_with_sinks.map(&:dom).
                map(&:data_flow_sinks))
        end
    end

    describe '#on_new_page' do
        it 'is passed each snapshot' do
            pages = []
            subject.on_new_page { |page| pages << page }

            expect(subject.load( url + '/explore' ).trigger_events.
                page_snapshots).to eq(pages)
        end

        it 'is passed each request capture' do
            pages = []
            subject.on_new_page { |page| pages << page }
            subject.start_capture

            # Last page will be the root snapshot so ignore it.
            expect(subject.load( url + '/with-ajax' ).captured_pages).to eq(pages[0...2])
        end
    end

    describe '#explore_and_flush' do
        it 'handles deep DOM/page transitions' do
            pages = subject.load( url + '/deep-dom', take_snapshot: true ).explore_and_flush

            pages_should_have_form_with_input pages, 'by-ajax'

            expect(pages.map(&:dom).map(&:transitions)).to eq([
                                                                  [
                                                                      { :page => :load }
                                                                  ],
                                                                  [
                                                                      { :page => :load },
                                                                      {
                                                                          {
                                                                              tag_name: 'a',
                                                                              attributes: {
                                                                                  'onmouseover' => 'writeButton();',
                                                                                  'href'        => '#'
                                                                              }
                                                                          } => :mouseover
                                                                      }
                                                                  ],
                                                                  [
                                                                      { :page => :load },
                                                                      {
                                                                          {
                                                                              tag_name: 'a',
                                                                              attributes: {
                                                                                  'href'        => 'javascript:level3();'
                                                                              }
                                                                          } => :click
                                                                      }
                                                                  ],
                                                                  [
                                                                      { :page => :load },
                                                                      {
                                                                          {
                                                                              tag_name: 'a',
                                                                              attributes: {
                                                                                  'onmouseover' => 'writeButton();',
                                                                                  'href'        => '#'
                                                                              }
                                                                          } => :mouseover
                                                                      },
                                                                      {
                                                                          {
                                                                              tag_name: 'button',
                                                                              attributes: {
                                                                                  'onclick' => 'writeUserAgent();',
                                                                              }
                                                                          } => :click
                                                                      }
                                                                  ],
                                                                  [
                                                                      { :page => :load },
                                                                      {
                                                                          {
                                                                              tag_name: 'a',
                                                                              attributes: {
                                                                                  'href'        => 'javascript:level3();'
                                                                              }
                                                                          } => :click
                                                                      },
                                                                      {
                                                                          {
                                                                              tag_name: 'div',
                                                                              attributes: {
                                                                                  'onclick' => 'level6();',
                                                                                  'id'      => 'level5'
                                                                              }
                                                                          } => :click
                                                                      }
                                                                  ]
                                                              ].map { |transitions| transitions_from_array( transitions ) })
        end

        context 'with a depth argument' do
            it 'does not go past the given DOM depth' do
                pages = subject.load( url + '/deep-dom', take_snapshot: true ).explore_and_flush(2)

                expect(pages.map(&:dom).map(&:transitions)).to eq([
                                                                      [
                                                                          { :page => :load }
                                                                      ],
                                                                      [
                                                                          { :page => :load },
                                                                          {
                                                                              {
                                                                                  tag_name: 'a',
                                                                                  attributes: {
                                                                                      'onmouseover' => 'writeButton();',
                                                                                      'href'        => '#'
                                                                                  }
                                                                              } => :mouseover
                                                                          }
                                                                      ],
                                                                      [
                                                                          { :page => :load },
                                                                          {
                                                                              {
                                                                                  tag_name: 'a',
                                                                                  attributes: {
                                                                                      'href'        => 'javascript:level3();'
                                                                                  }
                                                                              } => :click
                                                                          }
                                                                      ]
                                                                  ].map { |transitions| transitions_from_array( transitions ) })
            end
        end
    end

    describe '#page_snapshots_with_sinks' do
        it 'returns execution-flow sink data' do
            subject.load "#{url}/lots_of_sinks?input=#{subject.javascript.log_execution_flow_sink_stub(1)}", take_snapshot: true
            subject.explore_and_flush

            pages = subject.page_snapshots_with_sinks
            doms  = pages.map(&:dom)

            expect(doms.size).to eq(2)

            expect(doms[0].transitions).to eq(transitions_from_array([
                                                                         { page: :load },
                                                                         {
                                                                             {
                                                                                 tag_name:   'a',
                                                                                 attributes: {
                                                                                     'href'        => '#',
                                                                                     'onmouseover' => "onClick2('blah1', 'blah2', 'blah3');"
                                                                                 }
                                                                             } => :mouseover
                                                                         }
                                                                     ]))

            expect(doms[0].execution_flow_sinks.size).to eq(2)

            entry = doms[0].execution_flow_sinks[0]
            expect(entry.data).to eq([1])

            expect(entry.trace[0].function.name).to eq('onClick')
            expect(entry.trace[0].function.source).to start_with 'function onClick'
            expect(subject.source.split("\n")[entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(entry.trace[0].function.arguments).to eq([1, 2])

            expect(entry.trace[1].function.name).to eq('onClick2')
            expect(entry.trace[1].function.source).to start_with 'function onClick2'
            expect(subject.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick'
            expect(entry.trace[1].function.arguments).to eq(%w(blah1 blah2 blah3))

            expect(entry.trace[2].function.name).to eq('onmouseover')
            expect(entry.trace[2].function.source).to start_with 'function onmouseover'

            event = entry.trace[2].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            expect(event['target']).to eq(link)
            expect(event['type']).to eq('mouseover')

            entry = doms[0].execution_flow_sinks[1]
            expect(entry.data).to eq([1])

            expect(entry.trace[0].function.name).to eq('onClick3')
            expect(entry.trace[0].function.source).to start_with 'function onClick3'
            expect(subject.source.split("\n")[entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(entry.trace[0].function.arguments).to be_empty

            expect(entry.trace[1].function.name).to eq('onClick')
            expect(entry.trace[1].function.source).to start_with 'function onClick'
            expect(subject.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick3'
            expect(entry.trace[1].function.arguments).to eq([1, 2])

            expect(entry.trace[2].function.name).to eq('onClick2')
            expect(entry.trace[2].function.source).to start_with 'function onClick2'
            expect(subject.source.split("\n")[entry.trace[2].line - 1]).to include 'onClick'
            expect(entry.trace[2].function.arguments).to eq(%w(blah1 blah2 blah3))

            expect(entry.trace[3].function.name).to eq('onmouseover')
            expect(entry.trace[3].function.source).to start_with 'function onmouseover'

            event = entry.trace[3].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            expect(event['target']).to eq(link)
            expect(event['type']).to eq('mouseover')

            expect(doms[1].transitions).to eq(transitions_from_array([
                                                                         { page: :load },
                                                                         {
                                                                             {
                                                                                 tag_name:   'form',
                                                                                 attributes: {
                                                                                     'id'       => 'my_form',
                                                                                     'onsubmit' => "onClick('some-arg', 'arguments-arg', 'here-arg'); return false;"
                                                                                 }
                                                                             } => :submit
                                                                         }
                                                                     ]))

            expect(doms[1].execution_flow_sinks.size).to eq(2)

            entry = doms[1].execution_flow_sinks[0]
            expect(entry.data).to eq([1])

            expect(entry.trace[0].function.name).to eq('onClick')
            expect(entry.trace[0].function.source).to start_with 'function onClick'
            expect(subject.source.split("\n")[entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(entry.trace[0].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(entry.trace[1].function.name).to eq('onsubmit')
            expect(entry.trace[1].function.source).to start_with 'function onsubmit'
            # expect(subject.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick'

            event = entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['type']).to eq('submit')

            entry = doms[1].execution_flow_sinks[1]
            expect(entry.data).to eq([1])

            expect(entry.trace[0].function.name).to eq('onClick3')
            expect(entry.trace[0].function.source).to start_with 'function onClick3'
            expect(subject.source.split("\n")[entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(entry.trace[0].function.arguments).to be_empty

            expect(entry.trace[1].function.name).to eq('onClick')
            expect(entry.trace[1].function.source).to start_with 'function onClick'
            expect(subject.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick3()'
            expect(entry.trace[1].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(entry.trace[2].function.name).to eq('onsubmit')
            expect(entry.trace[2].function.source).to start_with 'function onsubmit'
            # expect(subject.source.split("\n")[entry.trace[2].line - 1]).to include 'onClick('

            event = entry.trace[2].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['type']).to eq('submit')
        end

        it 'returns data-flow sink data' do
            subject.javascript.taint = 'taint'
            subject.load "#{url}/lots_of_sinks?input=#{subject.javascript.log_data_flow_sink_stub( subject.javascript.taint, function: 'blah' )}"
            subject.explore_and_flush

            pages = subject.page_snapshots_with_sinks
            doms  = pages.map(&:dom)

            expect(doms.size).to eq(2)

            expect(doms[0].data_flow_sinks.size).to eq(2)

            entry = doms[0].data_flow_sinks[0]
            expect(entry.function).to eq('blah')

            expect(entry.trace[0].function.name).to eq('onClick')
            expect(entry.trace[0].function.source).to start_with 'function onClick'
            expect(subject.source.split("\n")[entry.trace[0].line - 1]).to include 'log_data_flow_sink('
            expect(entry.trace[0].function.arguments).to eq([1, 2])

            expect(entry.trace[1].function.name).to eq('onClick2')
            expect(entry.trace[1].function.source).to start_with 'function onClick2'
            expect(subject.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick'
            expect(entry.trace[1].function.arguments).to eq(%w(blah1 blah2 blah3))

            expect(entry.trace[2].function.name).to eq('onmouseover')
            expect(entry.trace[2].function.source).to start_with 'function onmouseover'

            event = entry.trace[2].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            expect(event['target']).to eq(link)
            expect(event['type']).to eq('mouseover')

            entry = doms[0].data_flow_sinks[1]
            expect(entry.function).to eq('blah')

            expect(entry.trace[0].function.name).to eq('onClick3')
            expect(entry.trace[0].function.source).to start_with 'function onClick3'
            expect(subject.source.split("\n")[entry.trace[0].line - 1]).to include 'log_data_flow_sink('
            expect(entry.trace[0].function.arguments).to be_empty

            expect(entry.trace[1].function.name).to eq('onClick')
            expect(entry.trace[1].function.source).to start_with 'function onClick'
            expect(subject.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick3'
            expect(entry.trace[1].function.arguments).to eq([1, 2])

            expect(entry.trace[2].function.name).to eq('onClick2')
            expect(entry.trace[2].function.source).to start_with 'function onClick2'
            expect(subject.source.split("\n")[entry.trace[2].line - 1]).to include 'onClick'
            expect(entry.trace[2].function.arguments).to eq(%w(blah1 blah2 blah3))

            expect(entry.trace[3].function.name).to eq('onmouseover')
            expect(entry.trace[3].function.source).to start_with 'function onmouseover'

            event = entry.trace[3].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            expect(event['target']).to eq(link)
            expect(event['type']).to eq('mouseover')

            expect(doms[1].data_flow_sinks.size).to eq(2)

            entry = doms[1].data_flow_sinks[0]
            expect(entry.function).to eq('blah')

            expect(entry.trace[0].function.name).to eq('onClick')
            expect(entry.trace[0].function.source).to start_with 'function onClick'
            expect(subject.source.split("\n")[entry.trace[0].line - 1]).to include 'log_data_flow_sink('
            expect(entry.trace[0].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(entry.trace[1].function.name).to eq('onsubmit')
            expect(entry.trace[1].function.source).to start_with 'function onsubmit'
            # expect(subject.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick'

            event = entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['type']).to eq('submit')

            entry = doms[1].data_flow_sinks[1]
            expect(entry.function).to eq('blah')

            expect(entry.trace[0].function.name).to eq('onClick3')
            expect(entry.trace[0].function.source).to start_with 'function onClick3'
            expect(subject.source.split("\n")[entry.trace[0].line - 1]).to include 'log_data_flow_sink('
            expect(entry.trace[0].function.arguments).to be_empty

            expect(entry.trace[1].function.name).to eq('onClick')
            expect(entry.trace[1].function.source).to start_with 'function onClick'
            expect(subject.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick3()'
            expect(entry.trace[1].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(entry.trace[2].function.name).to eq('onsubmit')
            expect(entry.trace[2].function.source).to start_with 'function onsubmit'
            # expect(subject.source.split("\n")[entry.trace[2].line - 1]).to include 'onClick('

            event = entry.trace[2].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['type']).to eq('submit')
        end

        describe 'when store_pages: false' do
            let(:options) { { store_pages: false } }

            it 'does not store pages' do
                subject.load "#{url}/lots_of_sinks?input=#{subject.javascript.log_execution_flow_sink_stub(1)}"
                subject.explore_and_flush
                expect(subject.page_snapshots_with_sinks).to be_empty
            end
        end
    end

    describe '#state' do
        it 'returns a Page::DOM with enough info to reproduce the current state' do
            subject.load "#{web_server_url_for( :taint_tracer )}/debug" <<
                              "?input=#{subject.javascript.log_execution_flow_sink_stub(1)}"

            dom   = subject.to_page.dom
            state = subject.state

            expect(state.page).to be_nil
            expect(state.url).to eq dom.url
            expect(state.digest).to eq dom.digest
            expect(state.transitions).to eq dom.transitions
            expect(state.skip_states).to eq dom.skip_states
            expect(state.data_flow_sinks).to be_empty
            expect(state.execution_flow_sinks).to be_empty
        end

        context 'when the URL is about:blank' do
            it 'returns nil' do
                SCNR::Engine::Options.url = url
                subject.load url

                subject.javascript.run( 'window.location = "about:blank";' )
                sleep 1

                expect(subject.state).to be_nil
            end
        end

        context 'when the resource is out-of-scope' do
            it 'returns an empty page' do
                SCNR::Engine::Options.url = url
                subject.load url

                subject.javascript.run( 'window.location = "http://google.com/";' )
                sleep 1

                expect(subject.state).to be_nil
            end
        end
    end

    describe '#to_page' do
        it "converts the working window to an #{SCNR::Engine::Page}" do
            subject.load( url )
            page = subject.to_page

            expect(page).to be_kind_of SCNR::Engine::Page

            expect(ua).not_to be_empty
            expect(page.response.body).not_to include( ua )
            expect(page.body).to include( ua )
        end

        it "assigns the proper #{SCNR::Engine::Page::DOM}#digest" do
            subject.load( url )
            expect(subject.to_page.dom.digest).to eq(-1247301223)
        end

        it "assigns the proper #{SCNR::Engine::Page::DOM}#transitions" do
            subject.load( url, take_snapshot: true )
            page = subject.to_page

            expect(page.dom.transitions).to eq(transitions_from_array([
                                                                          { page: :load }
                                                                      ]))
        end

        it "assigns the proper #{SCNR::Engine::Page::DOM}#skip_states" do
            subject.load( url )
            pages = subject.load( url + '/explore' ).trigger_events.
                page_snapshots

            page = pages.last
            expect(Set.new( page.dom.skip_states.collection.to_a )).to be_subset Set.new( subject.skip_states.collection.to_a )
        end

        it "assigns the proper #{SCNR::Engine::Page::DOM} sink data" do
            subject.load "#{web_server_url_for( :taint_tracer )}/debug" <<
                              "?input=#{subject.javascript.log_execution_flow_sink_stub(1)}"
            subject.watir.form.submit

            page = subject.to_page
            sink_data = page.dom.execution_flow_sinks

            first_entry = sink_data.first
            expect(sink_data).to eq([first_entry])

            expect(first_entry.data).to eq([1])

            expect(first_entry.trace[0].function.name).to eq('onClick')
            expect(first_entry.trace[0].function.source).to start_with 'function onClick'
            expect(subject.source.split("\n")[first_entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(first_entry.trace[0].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(first_entry.trace[1].function.name).to eq('onsubmit')
            expect(first_entry.trace[1].function.source).to start_with 'function onsubmit'
            # expect(subject.source.split("\n")[first_entry.trace[1].line - 1]).to include 'onClick('
            expect(first_entry.trace[1].function.arguments.size).to eq(1)

            event = first_entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['type']).to eq('submit')
        end

        it 'removes JS env modifications from the page body'
        it 'removes JS env modifications from the response body'

        context 'when the page has' do
            context "#{SCNR::Engine::Element::UIForm} elements" do
                context "and #{SCNR::Engine::OptionGroups::Audit}#inputs is" do
                    context 'true' do
                        before do
                            SCNR::Engine::Options.audit.elements :ui_forms
                        end

                        context '<input> button' do
                            context 'with DOM events' do
                                it 'parses it' do
                                    subject.load "#{url}/to_page/input/button/with_events"

                                    input = subject.to_page.ui_forms.first

                                    expect(input.action).to eq subject.url
                                    expect(input.source).to eq '<input id="insert" type="button">'
                                    expect(input.method).to eq :click
                                end
                            end

                            context 'without DOM events' do
                                it 'ignores it' do
                                    subject.load "#{url}/to_page/input/button/without_events"
                                    expect(subject.to_page.ui_forms).to be_empty
                                end
                            end
                        end

                        context '<button>' do
                            context 'with DOM events' do
                                it 'parses it' do
                                    subject.load "#{url}/to_page/button/with_events"

                                    input = subject.to_page.ui_forms.first

                                    expect(input.action).to eq subject.url
                                    expect(input.source).to eq '<button id="insert">'
                                    expect(input.method).to eq :click
                                end
                            end

                            context 'without DOM events' do
                                it 'ignores it' do
                                    subject.load "#{url}to_page/button/without_events"
                                    expect(subject.to_page.ui_forms).to be_empty
                                end
                            end
                        end
                    end

                    context 'false' do
                        before do
                            SCNR::Engine::Options.audit.skip_elements :ui_forms
                        end

                        it 'ignores them' do
                            subject.load "#{url}/to_page/button/with_events"
                            expect(subject.to_page.ui_forms).to be_empty
                        end
                    end
                end
            end

            context "#{SCNR::Engine::Element::UIInput} elements" do
                context "and #{SCNR::Engine::OptionGroups::Audit}#inputs is" do
                    context 'true' do
                        before do
                            SCNR::Engine::Options.audit.elements :ui_inputs
                        end

                        context '<input>' do
                            context 'with DOM events' do
                                it 'parses it' do
                                    subject.load "#{url}/to_page/input/with_events"

                                    input = subject.to_page.ui_inputs.first

                                    expect(input.action).to eq subject.url
                                    expect(input.source).to eq "<input id=\"my-input\" name=\"my-input\" oninput=\"handleOnInput();\" value=\"1\">"
                                    expect(input.method).to eq :input
                                end
                            end

                            context 'without DOM events' do
                                it 'ignores it' do
                                    subject.load "#{url}/to_page/input/without_events"
                                    expect(subject.to_page.ui_inputs).to be_empty
                                end
                            end
                        end

                        context '<textarea>' do
                            context 'with DOM events' do
                                it 'parses it' do
                                    subject.load "#{url}/to_page/textarea/with_events"

                                    input = subject.to_page.ui_inputs.first

                                    expect(input.action).to eq subject.url
                                    expect(input.source).to eq "<textarea id=\"my-input\" name=\"my-input\" oninput=\"handleOnInput();\">"
                                    expect(input.method).to eq :input
                                end
                            end

                            context 'without DOM events' do
                                it 'ignores it' do
                                    subject.load "#{url}/to_page/textarea/without_events"
                                    expect(subject.to_page.ui_inputs).to be_empty
                                end
                            end
                        end
                    end

                    context 'false' do
                        before do
                            SCNR::Engine::Options.audit.skip_elements :ui_inputs
                        end

                        it 'ignores them' do
                            subject.load "#{url}/to_page/input/with_events"
                            expect(subject.to_page.ui_inputs).to be_empty
                        end
                    end
                end
            end

            context "#{SCNR::Engine::Element::Form::DOM} elements" do
                context "and #{SCNR::Engine::OptionGroups::Audit}#forms is" do
                    context 'true' do
                        before do
                            SCNR::Engine::Options.audit.elements :forms
                        end

                        context 'and JavaScript action' do
                            it 'configures it to allow its DOM' do
                                subject.load "#{url}/each_element_with_events/form/action/javascript"
                                expect(subject.to_page.forms.first).not_to be_skip_dom
                            end
                        end

                        context 'with DOM events' do
                            it 'configures it to allow its DOM' do
                                subject.load "#{url}/fire_event/form/onsubmit"
                                expect(subject.to_page.forms.first).not_to be_skip_dom
                            end
                        end

                        context 'without DOM events' do
                            it 'configures it to skip its DOM' do
                                subject.load "#{url}/each_element_with_events/form/action/regular"
                                expect(subject.to_page.forms.first).to be_skip_dom
                            end
                        end
                    end

                    context 'false' do
                        before do
                            SCNR::Engine::Options.audit.skip_elements :forms
                        end

                        it 'configures it to skip its DOM' do
                            subject.load "#{url}/each_element_with_events/form/action/regular"
                            expect(subject.to_page.forms.first).to be_skip_dom
                        end
                    end
                end
            end

            context "#{SCNR::Engine::Element::Cookie::DOM} elements" do
                let(:cookies) { subject.to_page.cookies }

                context "and #{SCNR::Engine::OptionGroups::Audit}#cookies is" do
                    context 'true' do
                        before do
                            SCNR::Engine::Options.audit.elements :cookies

                            subject.load "#{url}/#{page}"
                            subject.load "#{url}/#{page}"
                        end

                        context 'with DOM processing of cookie' do
                            context 'names' do
                                let(:page) { 'dom-cookies-names' }

                                it 'configures it to allow its DOM' do
                                    expect(cookies.find { |c| c.name == 'js_cookie1' }).not_to be_skip_dom
                                    expect(cookies.find { |c| c.name == 'js_cookie2' }).not_to be_skip_dom
                                end

                                it 'does not track HTTP-only cookies' do
                                    expect(cookies.find { |c| c.name == 'http_only_cookie' }).to be_skip_dom
                                end

                                it 'does not track cookies for other paths' do
                                    expect(cookies.find { |c| c.name == 'other_path' }).to be_skip_dom
                                end
                            end

                            context 'values' do
                                let(:page) { 'dom-cookies-values' }

                                it 'configures it to skip its DOM' do
                                    expect(cookies.find { |c| c.name == 'js_cookie1' }).not_to be_skip_dom
                                    expect(cookies.find { |c| c.name == 'js_cookie2' }).not_to be_skip_dom
                                end

                                it 'does not track HTTP-only cookies' do
                                    expect(cookies.find { |c| c.name == 'http_only_cookie' }).to be_skip_dom
                                end

                                it 'does not track cookies for other paths' do
                                    expect(cookies.find { |c| c.name == 'other_path' }).to be_skip_dom
                                end
                            end
                        end

                        context 'without DOM processing of cookie' do
                            context 'names' do
                                let(:page) { 'dom-cookies-names' }

                                it 'configures it to skip its DOM' do
                                    expect(cookies.find { |c| c.name == 'js_cookie3' }).to be_skip_dom
                                end
                            end

                            context 'values' do
                                let(:page) { 'dom-cookies-values' }

                                it 'configures it to skip its DOM' do
                                    expect(cookies.find { |c| c.name == 'js_cookie3' }).to be_skip_dom
                                end
                            end
                        end

                        context 'when taints are not exact matches' do
                            context 'names' do
                                let(:page) { 'dom-cookies-names-substring' }

                                it 'configures it to skip its DOM' do
                                    expect(cookies.find { |c| c.name == 'js_cookie3' }).to be_skip_dom
                                end
                            end

                            context 'values' do
                                let(:page) { 'dom-cookies-values-substring' }

                                it 'configures it to skip its DOM' do
                                    expect(cookies.find { |c| c.name == 'js_cookie3' }).to be_skip_dom
                                end
                            end
                        end
                    end

                    context 'false' do
                        before do
                            SCNR::Engine::Options.audit.skip_elements :cookies

                            subject.load "#{url}/#{page}"
                            subject.load "#{url}/#{page}"
                        end

                        let(:page) { 'dom-cookies-names' }

                        it 'configures it to skip its DOM' do
                            expect(cookies).to be_any
                            cookies.each do |cookie|
                                expect(cookie).to be_skip_dom
                            end
                        end
                    end
                end
            end
        end

        context 'when the resource is out-of-scope' do
            it 'returns an empty page' do
                SCNR::Engine::Options.url = url
                subject.load url

                subject.javascript.run( 'window.location = "http://google.com/";' )
                sleep 1

                page = subject.to_page

                expect(page.code).to eq(0)
                expect(page.url).to  eq('http://google.com/')
                expect(page.body).to be_empty
                expect(page.dom.url).to eq('http://google.com/')
            end
        end

        context 'when #parse_profile' do
            context 'is disabled' do
                it "sets #{SCNR::Engine::Page::DOM}#url"
                it "sets #{SCNR::Engine::Page::DOM}#transitions"

                it "does not set #{SCNR::Engine::Page::DOM}#cookies"
                it "does not set #{SCNR::Engine::Page::DOM}#digest"
                it "does not set #{SCNR::Engine::Page::DOM}#execution_flow_sinks"
                it "does not set #{SCNR::Engine::Page::DOM}#data_flow_sinks"
                it "does not set #{SCNR::Engine::Page::DOM}#skip_states"

                it "does not set #{SCNR::Engine::Page}#body"
                it "does not set #{SCNR::Engine::Page}#ui_inputs"
                it "does not set #{SCNR::Engine::Page}#ui_forms"
            end

            context 'allows :body' do
                it "sets #{SCNR::Engine::Page}#body"
            end

            context 'allows :cookies' do
                it "sets #{SCNR::Engine::Page::DOM}#cookies"
            end

            context 'allows :digest' do
                it "sets #{SCNR::Engine::Page::DOM}#digest"
            end

            context 'allows :execution_flow_sinks' do
                it "sets #{SCNR::Engine::Page::DOM}#execution_flow_sinks"
            end

            context 'allows :data_flow_sinks' do
                it "sets #{SCNR::Engine::Page::DOM}#data_flow_sinks"
            end

            context 'allows :skip_states' do
                it "sets #{SCNR::Engine::Page::DOM}#skip_states"
            end

            context 'allows :elements' do
                it "sets #{SCNR::Engine::Page}#skip_states"
                it "sets #{SCNR::Engine::Page}#ui_inputs"
                it "sets #{SCNR::Engine::Page}#ui_forms"
            end
        end
    end

    describe '#start_capture' do
        before(:each) { subject.start_capture }

        it 'parses requests into elements of pages' do
            subject.load url + '/with-ajax'

            pages = subject.captured_pages
            expect(pages.size).to eq(2)

            has_input = false
            pages.each do |page|
                has_input ||= page.forms.find { |form| form.inputs.include? 'ajax-token' }
            end
            expect(has_input).to be_truthy
        end

        context 'when an element has already been seen' do
            context 'by the browser' do
                it 'ignores it' do
                    subject.load url + '/with-ajax'
                    expect(subject.captured_pages.size).to eq(2)
                    subject.captured_pages.clear

                    subject.load url + '/with-ajax'
                    expect(subject.captured_pages).to be_empty
                end
            end

            context "by the #{SCNR::Engine::ElementFilter}" do
                it 'ignores it' do
                    subject.load url + '/with-ajax'
                    SCNR::Engine::ElementFilter.update_forms subject.captured_pages.map(&:forms).flatten

                    subject = SCNR::Engine::Browser.new
                    subject.load url + '/with-ajax'
                    expect(subject.captured_pages).to be_empty
                end
            end
        end

        context 'when a GET request is performed' do
            it "is added as an #{SCNR::Engine::Element::Form} to the page" do
                subject.load url + '/with-ajax'

                pages = subject.captured_pages
                expect(pages.size).to eq(2)

                form = nil
                pages.each do |page|
                    form ||= page.forms.find { |f| f.inputs.include? 'ajax-token' }
                end

                expect(form.url).to eq(url + 'with-ajax')
                expect(form.action).to eq(url + 'get-ajax')
                expect(form.inputs).to eq({ 'ajax-token' => 'my-token' })
                expect(form.method).to eq(:get)
            end
        end

        context 'when a POST request is performed' do
            context 'with query parameters' do
                it "is added as an #{SCNR::Engine::Element::Form} to the page" do
                    subject.load url + '/with-ajax'

                    pages = subject.captured_pages
                    expect(pages.size).to eq(2)

                    form = find_page_with_form_with_input( pages, 'post-name' ).
                        forms.find { |form| form.inputs.include? 'post-query' }

                    expect(form.url).to eq(url + 'with-ajax')
                    expect(form.action).to eq(url + 'post-ajax')
                    expect(form.inputs).to eq({ 'post-query' => 'blah' })
                    expect(form.method).to eq(:get)
                end
            end

            context 'with form data' do
                it "is added as an #{SCNR::Engine::Element::Form} to the page" do
                    subject.load url + '/with-ajax'

                    pages = subject.captured_pages
                    expect(pages.size).to eq(2)

                    form = find_page_with_form_with_input( pages, 'post-name' ).
                        forms.find { |form| form.inputs.include? 'post-name' }

                    expect(form.url).to eq(url + 'with-ajax')
                    expect(form.action).to eq(url + 'post-ajax?post-query=blah')
                    expect(form.inputs).to eq({ 'post-name' => 'post-value' })
                    expect(form.method).to eq(:post)
                end
            end

            context 'with JSON data' do
                it "is added as an #{SCNR::Engine::Element::JSON} to the page" do
                    subject.load url + '/with-ajax-json'

                    pages = subject.captured_pages
                    expect(pages.size).to eq(1)

                    form = find_page_with_json_with_input( pages, 'post-name' ).
                        jsons.find { |json| json.inputs.include? 'post-name' }

                    expect(form.url).to eq(url + 'with-ajax-json')
                    expect(form.action).to eq(url + 'post-ajax')
                    expect(form.inputs).to eq({ 'post-name' => 'post-value' })
                    expect(form.method).to eq(:post)
                end
            end

            context 'with XML data' do
                it "is added as an #{SCNR::Engine::Element::XML} to the page" do
                    subject.load url + '/with-ajax-xml'

                    pages = subject.captured_pages
                    expect(pages.size).to eq(1)

                    form = find_page_with_xml_with_input( pages, 'input > text()' ).
                        xmls.find { |xml| xml.inputs.include? 'input > text()' }

                    expect(form.url).to eq(url + 'with-ajax-xml')
                    expect(form.action).to eq(url + 'post-ajax')
                    expect(form.inputs).to eq({ 'input > text()' => 'stuff' })
                    expect(form.method).to eq(:post)
                end
            end
        end
    end

    describe '#flush_pages' do
        it 'flushes the captured pages' do
            subject.start_capture
            subject.load url + '/with-ajax'

            pages = subject.flush_pages
            expect(pages.size).to eq(2)
            expect(subject.flush_pages).to be_empty
        end
    end

    describe '#stop_capture' do
        it 'stops the page capture' do
            subject.stop_capture
            expect(subject.capture?).to be_falsey
        end
    end

    describe 'capture?' do
        it 'returns false' do
            subject.start_capture
            subject.stop_capture
            expect(subject.capture?).to be_falsey
        end

        context 'when capturing pages' do
            it 'returns true' do
                subject.start_capture
                expect(subject.capture?).to be_truthy
            end
        end
        context 'when not capturing pages' do
            it 'returns false' do
                subject.start_capture
                subject.stop_capture
                expect(subject.capture?).to be_falsey
            end
        end
    end

end
