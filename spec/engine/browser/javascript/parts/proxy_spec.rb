require 'spec_helper'

describe SCNR::Engine::Browser::Javascript::Parts::Proxy do
    include_examples 'javascript'

    describe '#serve' do
        context 'when the request URL is' do
            let(:content_type) { 'text/javascript' }
            let(:content_length) { body.bytesize.to_s }
            let(:request) { SCNR::Engine::HTTP::Request.new( url: url ) }
            let(:response) do
                SCNR::Engine::HTTP::Response.new(
                    url:     url,
                    request: request
                )
            end

            context described_class::ENV_SCRIPT_URL do
                let(:url) { "http://#{described_class::ENV_SCRIPT_URL}" }

                before(:each){ subject.serve( request, response ) }

                it 'sets the correct status code' do
                    expect(response.code).to eq(200)
                end

                context 'the the response body includes' do
                    %W(dom_monitor.js taint_tracer.js polyfills.js events.js).each do |filename|
                        context 'the system' do
                            it filename
                        end

                        context 'then engine' do
                            it filename
                        end
                    end
                end

                it 'includes the DOMMonitor initializer'

                it 'includes the TaintTracer initializer'

                it 'includes the env initialization signal'

                it 'includes the #custom_code'

                it 'sets the correct Content-Type' do
                    expect(response.headers.content_type).to eq(content_type)
                end

                it 'sets the correct Content-Length'

                it 'returns true' do
                    expect(subject.serve( request, response )).to be_truthy
                end
            end

            context 'other' do
                let(:url) { 'http://google.com/' }

                it 'returns false' do
                    expect(subject.serve( request, response )).to be_falsey
                end
            end
        end
    end

    describe '#inject' do
        let(:env_update_function) do
            "#{subject.env_update_function};"
        end

        context 'when the response is' do
            context 'JavaScript' do
                let(:response) do
                    SCNR::Engine::HTTP::Response.new(
                        url:     "#{dom_monitor_url}/jquery.js",
                        headers: {
                            'Content-Type' => 'text/javascript'
                        },
                        body: <<EOHTML
                            foo()
EOHTML
                    )
                end

                let(:injected) do
                    r = response.deep_clone
                    subject.inject( r )
                    r
                end

                let(:dom_monitor_update) do
                    "#{subject.dom_monitor.stub.function( :update_trackers )};"
                end

                it 'does not introduce new lines'

                it 'injects the env update function call before the code' do
                    expect(injected.body).to start_with env_update_function
                end

                it 'injects the env update function call after the code' do
                    expect(injected.body).to end_with ";#{env_update_function}"
                end
            end

            context 'HTML' do
                let(:response) do
                    SCNR::Engine::HTTP::Response.new(
                        url:     dom_monitor_url,
                        headers: {
                            'Content-Type' => 'text/html'
                        },
                        body: <<EOHTML
                            <body>
                            </body>
EOHTML
                    )
                end

                context 'when the response does not already contain the JS env' do
                    context 'over HTTP' do
                        it 'injects the JS env over HTTP' do
                            env_url = "http://#{described_class::ENV_SCRIPT_URL}?" <<
                                described_class::ENV_SCRIPT_DATA_START <<
                                Base64.urlsafe_encode64( response.parsed_url.without_query ) <<
                                described_class::ENV_SCRIPT_DATA_END

                            subject.inject( response )
                            expect(Nokogiri::HTML( response.body.to_string_io.string ).xpath( "//script[@src='#{env_url}']" ).size).to eq 1
                        end
                    end

                    context 'over HTTPS' do
                        before { response.url = response.url.gsub( 'http', 'https' ) }

                        it 'injects the JS env over HTTPS' do
                            env_url = "https://#{described_class::ENV_SCRIPT_URL}?" <<
                                described_class::ENV_SCRIPT_DATA_START <<
                                Base64.urlsafe_encode64( response.parsed_url.without_query ) <<
                                described_class::ENV_SCRIPT_DATA_END

                            subject.inject( response )
                            expect(Nokogiri::HTML( response.body.to_string_io.string ).xpath( "//script[@src='#{env_url}']" ).size).to eq 1
                        end
                    end

                    context 'when the response body contains script elements' do
                        before { response.body = '<script>// My code and stuff</script>' }

                        it 'does not introduce new lines'

                        it 'wraps the script code in env update calls' do
                            subject.inject( response )
                            expect(Nokogiri::HTML(response.body.to_string_io.string).css('script').last.to_s).to eq(
                                "<script>/* #{SCNR::Engine::Browser::Javascript.token}RemoveLine */ " <<
                                    "#{SCNR::Engine::Browser::Javascript.token}EnvUpdate();// " <<
                                    "My code and stuff;/* #{SCNR::Engine::Browser::Javascript.token}RemoveLine " <<
                                    "*/ #{SCNR::Engine::Browser::Javascript.token}EnvUpdate();</script>"
                            )
                        end
                    end
                end

                context 'when the response already contains the JS env' do
                    it 'ignores it' do
                        subject.inject( response )

                        presponse = response.deep_clone

                        expect(subject.inject( response )).to be_falsey
                        expect(response.body.to_string_io.string).to eq(presponse.body.to_string_io.string)
                    end
                end
            end
        end
    end

end
