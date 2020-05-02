require 'spec_helper'

describe SCNR::Engine::Browser::Javascript::Parts::Helpers do
    include_examples 'javascript'

    describe '#remove_env_from_html' do
        it 'removes environment modifications from HTML code'
    end

    describe '#remove_env_from_js' do
        it 'removes environment modifications from JS code'
    end

    describe '#javascript?' do
        context 'when the Content-Type includes javascript' do
            it 'returns true'
        end

        context 'when the Content-Type does not include javascript' do
            it 'returns false'
        end
    end

    describe '#html?' do
        context 'when the body is empty' do
            it 'returns false'
        end

        context 'when it matches the last loaded URL' do
            it 'returns true'
        end

        context 'when it contains markup' do
            it 'returns true'
        end
    end

    describe '#log_execution_flow_sink_stub' do
        it 'returns JS code for TaintTracer.log_execution_flow_sink()' do
            expect(subject.log_execution_flow_sink_stub( 1, 2, 3 )).to eq(
                                                                           "#{subject.token}TaintTracer.log_execution_flow_sink(1, 2, 3)"
                                                                       )
        end
    end

    describe '#log_data_flow_sink_stub' do
        it 'returns JS code for TaintTracer.log_data_flow_sink()' do
            expect(subject.log_data_flow_sink_stub( 1, 2, 3 )).to eq(
                                                                      "#{subject.token}TaintTracer.log_data_flow_sink(1, 2, 3)"
                                                                  )
        end
    end

    describe '#debug_stub' do
        it 'returns JS code for TaintTracer.debug()' do
            expect(subject.debug_stub( 1, 2, 3 )).to eq(
                                                         "#{subject.token}TaintTracer.debug(1, 2, 3)"
                                                     )
        end
    end

    describe '#log_execution_flow_sink_stub' do
        it 'returns JS code that calls JS\'s log_execution_flow_sink_stub()' do
            expect(subject.log_execution_flow_sink_stub).to eq(
                                                                "#{subject.token}TaintTracer.log_execution_flow_sink()"
                                                            )

            browser.load "#{taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub}"

            browser.watir.form.submit
            expect(subject.execution_flow_sinks).to be_any
            expect(subject.execution_flow_sinks.first.data).to be_empty
        end
    end

    describe '#set_element_ids' do
        it 'sets custom ID attributes to elements with events but without ID' do
            browser.load( dom_monitor_url + 'set_element_ids' )

            as = browser.watir.as

            expect(as[0].name).to eq('1')
            expect(as[0].html).not_to include 'data-scnr-engine-id'

            expect(as[1].name).to eq('2')
            expect(as[1].html).to include 'data-scnr-engine-id'

            expect(as[2].name).to eq('3')
            expect(as[2].html).not_to include 'data-scnr-engine-id'

            expect(as[3].name).to eq('4')
            expect(as[3].html).not_to include 'data-scnr-engine-id'
        end
    end

    describe '#dom_digest' do
        it 'returns a string digest of the current DOM tree' do
            browser.load( dom_monitor_url + 'digest' )
            expect(subject.dom_digest).to eq(subject.dom_monitor.digest)
        end
    end

    describe '#has_sinks?' do
        context 'when there are execution-flow sinks' do
            it 'returns true' do
                expect(subject).to_not have_sinks

                browser.load "#{taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub(1)}"
                browser.watir.form.submit

                expect(subject).to have_sinks
            end
        end

        context 'when there are data-flow sinks' do
            context 'for the given taint' do
                it 'returns true' do
                    expect(subject).to_not have_sinks

                    subject.taint = 'taint'
                    browser.load "#{taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub( subject.taint, function: { name: 'blah' } )}"
                    browser.watir.form.submit

                    expect(subject).to have_sinks
                end
            end

            context 'for other taints' do
                it 'returns false' do
                    expect(subject).to_not have_sinks

                    subject.taint = 'taint'
                    browser.load "#{taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub( subject.taint, function: { name: 'blah' } )}"
                    browser.watir.form.submit

                    subject.taint = 'taint2'
                    expect(subject).to_not have_sinks
                end
            end
        end

        context 'when there are no sinks' do
            it 'returns false' do
                expect(subject).to_not have_sinks
            end
        end
    end

    describe '#debugging_data' do
        it 'returns debugging information' do
            browser.load "#{taint_tracer_url}/debug?input=#{subject.debug_stub(1)}"
            browser.watir.form.submit
            expect(subject.debugging_data).to eq(subject.taint_tracer.debugging_data)
        end
    end

    describe '#execution_flow_sinks' do
        it 'returns sink data' do
            browser.load "#{taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub(1)}"
            browser.watir.form.submit

            expect(subject.execution_flow_sinks).to be_any
            expect(subject.execution_flow_sinks).to eq(subject.taint_tracer.execution_flow_sinks)
        end
    end

    describe '#data_flow_sinks' do
        it 'returns sink data' do
            browser.javascript.taint = 'taint'
            browser.load "#{taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub( browser.javascript.taint, function: { name: 'blah' } )}"
            browser.watir.form.submit

            sinks = subject.data_flow_sinks
            expect(sinks).to be_any
            expect(sinks).to eq(subject.taint_tracer.data_flow_sinks[browser.javascript.taint])
        end
    end

    describe '#flush_data_flow_sinks' do
        before do
            browser.javascript.taint = 'taint'
        end

        it 'returns sink data' do
            browser.load "#{taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub( browser.javascript.taint, function: { name: 'blah' } )}"
            browser.watir.form.submit

            sink = subject.flush_data_flow_sinks
            sink[0].trace[1].function.arguments[0].delete( 'timeStamp' )

            browser.load "#{taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub( browser.javascript.taint, function: { name: 'blah' } )}"
            browser.watir.form.submit

            sink2 = subject.taint_tracer.data_flow_sinks[browser.javascript.taint]
            sink2[0].trace[1].function.arguments[0].delete( 'timeStamp' )

            expect(sink).to eq(sink2)
        end

        it 'empties the sink' do
            browser.load "#{taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub}"
            browser.watir.form.submit

            subject.flush_data_flow_sinks
            expect(subject.data_flow_sinks).to be_empty
        end
    end

    describe '#flush_execution_flow_sinks' do
        it 'returns sink data' do
            browser.load "#{taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub(1)}"
            browser.watir.form.submit

            sink = subject.flush_execution_flow_sinks
            sink[0].trace[1].function.arguments[0].delete( 'timeStamp' )

            browser.load "#{taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub(1)}"
            browser.watir.form.submit

            sink2 = subject.taint_tracer.execution_flow_sinks
            sink2[0].trace[1].function.arguments[0].delete( 'timeStamp' )

            expect(sink).to eq(sink2)
        end

        it 'empties the sink' do
            browser.load "#{taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub}"
            browser.watir.form.submit

            subject.flush_execution_flow_sinks
            expect(subject.execution_flow_sinks).to be_empty
        end
    end

end
