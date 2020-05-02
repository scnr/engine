require 'spec_helper'
require "#{SCNR::Engine::Options.paths.lib}/rest/server"

describe SCNR::Engine::Rest::Server do
    include RequestHelpers

    before(:each) do
        app.reset
        SCNR::Engine::Options.system.max_slots = 10
    end

    let(:target) { web_server_url_for(:framework) }
    let(:url) { tpl_url % id }
    let(:id) { @id }
    let(:non_existent_id) { 'stuff' }

    let(:dispatcher) { SCNR::Engine::Processes::Dispatchers.spawn }
    let(:queue) { SCNR::Engine::Processes::Queues.spawn }

    def create_scan
        post '/scans',
             url:             target,
             checks:          ['test'],
             audit:           {
                 elements:    [:links, :forms, :cookies]
             }
        response_data['id']
    end

    context 'supports compressing as' do
        ['deflate','gzip', 'deflate,gzip','gzip,deflate'].each do |compression_method|

            it compression_method do
                get '/', {}, { 'HTTP_ACCEPT_ENCODING' => compression_method }
                expect( response.headers['Content-Encoding'] ).to eq compression_method.split( ',' ).first
            end

        end
    end

    context 'when the client does not support compression' do
        it 'does not compress the response' do
            get '/'
            expect(response.headers['Content-Encoding']).to be_nil
        end
    end

    context 'when authentication' do
        let(:username) { nil }
        let(:password) { nil }
        let(:userpwd) { "#{username}:#{password}" }
        let(:url) { "http://localhost:#{SCNR::Engine::Options.rpc.server_port}/scans" }

        before do
            SCNR::Engine::Options.datastore['username'] = username
            SCNR::Engine::Options.datastore['password'] = password

            SCNR::Engine::Options.rpc.server_port = SCNR::Engine::Utilities.available_port
            SCNR::Engine::Processes::Manager.spawn( :rest_service )

            sleep 0.1 while Typhoeus.get( url ).code == 0
        end

        after do
            SCNR::Engine::Processes::Manager.killall
        end

        context 'username' do
            let(:username) { 'username' }

            context 'is configured' do
                it 'requires authentication' do
                    expect(Typhoeus.get( url ).code).to eq 401
                    expect(Typhoeus.get( url, userpwd: userpwd ).code).to eq 200
                end
            end
        end

        context 'password' do
            let(:password) { 'password' }

            context 'is configured' do
                it 'requires authentication' do
                    expect(Typhoeus.get( url ).code).to eq 401
                    expect(Typhoeus.get( url, userpwd: userpwd ).code).to eq 200
                end
            end
        end
    end

    describe 'SSL options', if: !SCNR::Engine.windows? do
        let(:ssl_key) { nil }
        let(:ssl_cert) { nil }
        let(:ssl_ca) { nil }
        let(:url) { "http://localhost:#{SCNR::Engine::Options.rpc.server_port}/scans" }
        let(:https_url) { "https://localhost:#{SCNR::Engine::Options.rpc.server_port}/scans" }

        before do
            SCNR::Engine::Options.rpc.ssl_ca                 = ssl_ca
            SCNR::Engine::Options.rpc.server_ssl_private_key = ssl_key
            SCNR::Engine::Options.rpc.server_ssl_certificate = ssl_cert

            SCNR::Engine::Options.rpc.server_port = SCNR::Engine::Utilities.available_port
            SCNR::Engine::Processes::Manager.spawn( :rest_service )

            sleep 0.1 while Typhoeus.get( url ).return_code == :couldnt_connect
        end

        after do
            SCNR::Engine::Processes::Manager.killall
        end

        describe 'when key and certificate is given' do
            let(:ssl_key) { "#{support_path}/pems/server/key.pem" }
            let(:ssl_cert) { "#{support_path}/pems/server/cert.pem" }

            describe 'when no CA is given' do
                it 'disables peer verification' do
                    expect(Typhoeus.get( https_url, ssl_verifypeer: false ).code).to eq 200
                end
            end

            describe 'a CA is given' do
                let(:ssl_ca) { "#{support_path}/pems/cacert.pem" }

                it 'enables peer verification' do
                    expect(Typhoeus.get( https_url, ssl_verifypeer: false ).code).to eq 0

                    expect(Typhoeus.get(
                        https_url,
                        ssl_verifypeer: true,
                        sslcert:        "#{support_path}/pems/client/cert.pem",
                        sslkey:         "#{support_path}/pems/client/key.pem",
                        cainfo:         ssl_ca
                    ).code).to eq 200
                end
            end
        end

        describe 'when only key is given' do
            let(:ssl_key) { "#{support_path}/pems/server/key.pem" }

            it 'does not enable SSL' do
                expect(Typhoeus.get( url ).code).to eq 200
            end
        end

        describe 'when only cert is given' do
            let(:ssl_cert) { "#{support_path}/pems/server/cert.pem" }

            it 'does not enable SSL' do
                expect(Typhoeus.get( url ).code).to eq 200
            end
        end
    end

    describe 'GET /scans' do
        let(:tpl_url) { '/scans' }

        it 'lists ids for all instances' do
            ids = []
            2.times do
                ids << create_scan
            end

            get url

            ids.each do |id|
                expect(response_data[id]).to eq({})
            end
        end

        context 'when there is a Queue' do
            before do
                put '/queue/url', queue.url
            end

            it 'includes its running scans' do
                id = queue.push( url: target )
                sleep 0.1 while queue.running.empty?

                get url
                expect(response_data).to include id
            end

            context 'when a running scan completes' do
                it 'is removed' do
                    queue.push( url: target )
                    sleep 0.1 while queue.completed.empty?

                    get url
                    expect(response_data).to be_empty
                end
            end
        end
    end

    describe 'POST /scans' do
        let(:tpl_url) { '/scans' }

        it 'creates a scan' do
            post url, url: target
            expect(response_code).to eq 200
        end

        context 'when given invalid options' do
            it 'returns a 500' do
                post url, stuff: target

                expect(response_code).to eq 500
                expect(response_data['error']).to eq 'Arachni::RPC::Exceptions::RemoteException'
                expect(response_data).to include 'backtrace'
            end

            it 'does not list the instance on the index' do
                get '/scans'
                ids = response_data.keys

                post url, stuff: target

                get '/scans'
                expect(response_data.keys - ids).to be_empty
            end
        end

        context 'when the system is at max utilization' do
            it 'returns a 503' do
                SCNR::Engine::Options.system.max_slots = 1

                post url, url: target
                expect(response_code).to eq 200

                sleep 1

                post url, url: target
                expect(response_code).to eq 503
                expect(response_data['error']).to eq 'Service unavailable: System is at maximum ' +
                                                         'utilization, slot limit reached.'
            end
        end

        context 'when a Dispatcher has been set' do

            it 'uses it' do
                put '/dispatcher/url', dispatcher.url

                get "/grid/#{dispatcher.url}"
                expect(response_data['running_instances']).to be_empty

                create_scan

                get "/grid/#{dispatcher.url}"
                expect(response_data['running_instances'].size).to eq 1
            end
        end
    end

    describe 'GET /scans/:scan' do
        let(:tpl_url) { '/scans/%s' }

        before do
            @id = create_scan
        end

        it 'gets progress info' do
            loop do
                get url
                break if !response_data['busy']
                sleep 0.5
            end

            %w(errors status busy messages statistics).each do |key|
                expect(response_data).to include key
            end

            %w(issues sitemap statistics).each do |key|
                expect(response_data.any?).to be_truthy
            end
        end

        context 'when a session is maintained' do
            it 'only returns new issues'
            it 'only returns new errors'
            it 'only returns new sitemap entries'
        end

        context 'when a session is not maintained' do
            it 'always returns all issues'
            it 'always returns all errors'
            it 'always returns all sitemap entries'
        end

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                get url
                expect(response_code).to eq 404
            end
        end

        context 'when the scan is from the Queue' do
            before do
                put '/queue/url', queue.url
            end

            it 'includes it' do
                @id = queue.push( url: target )
                sleep 0.1 while queue.running.empty?

                get url
                expect(response_data).to include 'busy'
            end

            context 'when the scan completes' do
                it 'is removed' do
                    @id = queue.push( url: target )
                    sleep 0.1 while queue.completed.empty?

                    get url
                    expect(response_code).to be 404
                end
            end
        end
    end

    describe 'PUT /scans/:scan/queue' do
        let(:tpl_url) { '/scans/%s/queue' }

        before do
            @id = create_scan
        end

        context 'when there is a Queue' do
            before do
                put '/queue/url', queue.url
            end

            it 'moves the scan to the Queue' do
                expect(queue.running).to be_empty

                put url
                expect(response_code).to be 200
                expect(queue.running).to include @id
            end

            context 'but the scan could not be found' do
                it 'returns 404' do
                    @id = 'ss'

                    put url
                    expect(response_code).to be 404
                end
            end
        end

        context 'when there is no Queue' do
            it 'returns 501' do
                put url
                expect(response_code).to be 501
            end
        end
    end

    describe 'GET /scans/:scan/summary' do
        let(:tpl_url) { '/scans/%s/summary' }

        before do
            @id = create_scan
        end

        it 'does not include issues and sitemap' do
            loop do
                get url
                break if !response_data['busy']
                sleep 0.5
            end

            %w(status busy messages statistics).each do |key|
                expect(response_data).to include key
            end

            %w(issues sitemap errors).each do |key|
                expect(response_data).to_not include key
            end
        end

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                get url
                expect(response_code).to eq 404
            end
        end

        context 'when the scan is from the Queue' do
            before do
                put '/queue/url', queue.url
            end

            it 'includes it' do
                @id = queue.push( url: target )
                sleep 0.1 while queue.running.empty?

                get url
                expect(response_data).to include 'busy'
            end

            context 'when the scan completes' do
                it 'is removed' do
                    @id = queue.push( url: target )
                    sleep 0.1 while queue.completed.empty?

                    get url
                    expect(response_code).to be 404
                end
            end
        end
    end

    describe 'GET /scans/:scan/report.:format' do
        let(:tpl_url) { "/scans/%s/report.#{format}" }

        describe 'without format' do
            let(:tpl_url) { '/scans/%s/report' }

            before do
                @id = create_scan
            end

            it 'returns scan report as JSON' do
                get url

                %w(version options issues sitemap plugins start_datetime
                finish_datetime).each do |key|
                    expect(response_data).to include key
                end
            end

            it 'has content-type application/json' do
                get url
                expect(last_response.headers['content-type']).to eq 'application/json'
            end

            context 'when passed a non-existent id' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    get url
                    expect(response_code).to eq 404
                end
            end
        end

        describe 'json' do
            let(:format) { 'json' }

            before do
                @id = create_scan
            end

            it 'returns scan report as JSON' do
                get url

                %w(version options issues sitemap plugins start_datetime
                finish_datetime).each do |key|
                    expect(response_data).to include key
                end
            end

            it 'has content-type application/json' do
                get url
                expect(last_response.headers['content-type']).to eq 'application/json'
            end

            context 'when passed a non-existent id' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    get url
                    expect(response_code).to eq 404
                end
            end
        end

        describe 'xml' do
            let(:format) { 'xml' }

            before do
                @id = create_scan
            end

            it 'returns scan report as XML' do
                get url

                %w(version options issues sitemap plugins start_datetime
                finish_datetime).each do |key|
                    expect(
                        response_body.include?( "<#{key}>") ||
                            response_body.include?( "<#{key}/>")
                    ).to be_truthy
                end
            end

            it 'has content-type application/xml' do
                get url
                expect(last_response.headers['content-type']).to eq 'application/xml;charset=utf-8'
            end

            context 'when passed a non-existent id' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    get url
                    expect(response_code).to eq 404
                end
            end
        end

        describe 'yaml' do
            let(:format) { 'yaml' }

            before do
                @id = create_scan
            end

            it 'returns scan report as YAML' do
                get url

                data = YAML.load( response_body )
                %w(version options issues sitemap plugins start_datetime
                finish_datetime).each do |key|
                    expect(data).to include key.to_sym
                end
            end

            it 'has content-type text/yaml' do
                get url
                expect(last_response.headers['content-type']).to eq 'text/yaml;charset=utf-8'
            end

            context 'when passed a non-existent id' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    get url
                    expect(response_code).to eq 404
                end
            end
        end

        describe 'html.zip' do
            let(:format) { 'html.zip' }

            before do
                @id = create_scan
            end

            it 'returns scan report as a zipped HTML' do
                get url

                expect(response_body).to start_with 'PK'
            end

            it 'has content-type application/zip' do
                get url
                expect(last_response.headers['content-type']).to eq 'application/zip'
            end

            context 'when passed a non-existent id' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    get url
                    expect(response_code).to eq 404
                end
            end
        end

        describe 'invalid format' do
            let(:format) { 'blah' }

            before do
                @id = create_scan
            end

            it 'returns 400' do
                get url
                expect(response_code).to eq 400
            end
        end
    end

    describe 'PUT /scans/:scan/pause' do
        let(:tpl_url) { '/scans/%s/pause' }

        before do
            @id = create_scan
        end

        it 'pauses the scan' do
            put url
            expect(response_code).to eq 200

            get "/scans/#{id}"
            expect(['pausing', 'paused']).to include response_data['status']
        end

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                put url
                expect(response_code).to eq 404
            end
        end

        context 'when the scan is from the Queue' do
            before do
                put '/queue/url', queue.url
            end

            it 'includes it' do
                @id = queue.push( url: target )
                sleep 0.1 while queue.running.empty?

                put url
                expect(response_code).to eq 200

                get "/scans/#{id}"
                expect(['pausing', 'paused']).to include response_data['status']
            end

            context 'when the scan completes' do
                it 'is removed' do
                    @id = queue.push( url: target )
                    sleep 0.1 while queue.completed.empty?

                    put url
                    expect(response_code).to be 404
                end
            end
        end
    end

    describe 'PUT /scans/:scan/resume' do
        let(:tpl_url) { '/scans/%s/resume' }

        before do
            @id = create_scan
        end

        it 'resumes the scan' do
            put "/scans/#{id}/pause"
            get "/scans/#{id}"

            expect(['pausing', 'paused']).to include response_data['status']

            put url
            get "/scans/#{id}"

            expect(response_data['status']).to eq 'scanning'
        end

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                put url
                expect(response_code).to eq 404
            end
        end

        context 'when the scan is from the Queue' do
            before do
                put '/queue/url', queue.url
            end

            it 'includes it' do
                @id = queue.push( url: target )
                sleep 0.1 while queue.running.empty?

                put "/scans/#{id}/pause"
                get "/scans/#{id}"

                expect(['pausing', 'paused']).to include response_data['status']

                put url
                get "/scans/#{id}"

                expect(['scanning', 'done']).to include response_data['status']
            end

            context 'when the scan completes' do
                it 'is removed' do
                    @id = queue.push( url: target )
                    sleep 0.1 while queue.completed.empty?

                    put url
                    expect(response_code).to be 404
                end
            end
        end
    end

    describe 'DELETE /scans/:scan' do
        let(:tpl_url) { '/scans/%s' }

        before do
            @id = create_scan
        end

        it 'aborts the scan' do
            get url
            expect(response_code).to eq 200

            delete url

            get "/scans/#{id}"
            expect(response_code).to eq 404
        end

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                delete url
                expect(response_code).to eq 404
            end
        end

        context 'when the scan is from the Queue' do
            before do
                put '/queue/url', queue.url
            end

            it 'includes it' do
                @id = queue.push( url: target )
                sleep 0.1 while queue.running.empty?

                delete url
                expect(response_code).to eq 200

                sleep 0.1 while queue.failed.empty?

                expect(queue.failed).to include @id
            end

            context 'when the scan completes' do
                it 'is removed' do
                    @id = queue.push( url: target )
                    sleep 0.1 while queue.completed.empty?

                    delete url
                    expect(response_code).to be 404
                end
            end
        end
    end

    describe 'GET /dispatcher/url' do
        let(:tpl_url) { '/dispatcher/url' }

        it 'returns the Dispatcher' do
            put url, dispatcher.url
            expect(response_code).to eq 200

            get url
            expect(response_code).to eq 200
            expect(response_data).to eq dispatcher.url
        end

        context 'when no Dispatcher has been set' do
            it 'returns 501' do
                get url
                expect(response_code).to eq 501
                expect(response_data).to eq 'No Dispatcher has been set.'
            end
        end
    end

    describe 'PUT /dispatcher/url' do
        let(:tpl_url) { '/dispatcher/url' }

        it 'sets the Dispatcher' do
            put url, dispatcher.url
            expect(response_code).to eq 200
        end

        context 'when passed a non-existent URL' do
            let(:id) { non_existent_id }

            it 'returns 500' do
                put url, 'localhost:383838'
                expect(response_code).to eq 500
                expect(response_data['error']).to eq 'Arachni::RPC::Exceptions::ConnectionError'
            end
        end
    end

    describe 'DELETE /dispatcher/url' do
        let(:tpl_url) { '/dispatcher/url' }

        it 'removes the the Dispatcher' do
            put url, dispatcher.url
            expect(response_code).to eq 200

            delete url
            expect(response_code).to eq 200

            get url, dispatcher.url
            expect(response_code).to eq 501
        end

        context 'when no Dispatcher has been set' do
            it 'returns 501' do
                delete url
                expect(response_code).to eq 501
                expect(response_data).to eq 'No Dispatcher has been set.'
            end
        end
    end

    describe 'GET /grid' do
        let(:dispatcher) { SCNR::Engine::Processes::Dispatchers.grid_spawn }
        let(:tpl_url) { '/grid' }

        it 'returns Grid info' do
            put '/dispatcher/url', dispatcher.url
            expect(response_code).to eq 200

            get url
            expect(response_code).to eq 200
            expect(response_data.sort).to eq ([dispatcher.url] + dispatcher.node.neighbours).sort
        end

        context 'when no Dispatcher has been set' do
            it 'returns 501' do
                get url
                expect(response_code).to eq 501
                expect(response_data).to eq 'No Dispatcher has been set.'
            end
        end
    end

    describe 'GET /grid/:dispatcher' do
        let(:dispatcher) { SCNR::Engine::Processes::Dispatchers.grid_spawn }
        let(:tpl_url) { '/grid/%s' }

        it 'returns Dispatcher info' do
            put '/dispatcher/url', dispatcher.url
            expect(response_code).to eq 200

            @id = dispatcher.url

            get url
            expect(response_code).to eq 200
            expect(response_data).to eq dispatcher.statistics
        end

        context 'when no Dispatcher has been set' do
            it 'returns 501' do
                @id = 'localhost:2222'

                get url
                expect(response_code).to eq 501
                expect(response_data).to eq 'No Dispatcher has been set.'
            end
        end
    end

    describe 'DELETE /grid/:dispatcher' do
        let(:dispatcher) { SCNR::Engine::Processes::Dispatchers.grid_spawn }
        let(:tpl_url) { '/grid/%s' }

        it 'unplugs the Dispatcher from the Grid' do
            put '/dispatcher/url', dispatcher.url
            expect(response_code).to eq 200

            @id = dispatcher.url

            expect(dispatcher.node.grid_member?).to be_truthy

            delete url
            expect(response_code).to eq 200
            expect(dispatcher.node.grid_member?).to be_falsey
        end

        context 'when no Dispatcher has been set' do
            it 'returns 501' do
                @id = 'localhost:2222'

                delete url
                expect(response_code).to eq 501
                expect(response_data).to eq 'No Dispatcher has been set.'
            end
        end
    end

    describe 'GET /queue' do
        let(:tpl_url) { '/queue' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'lists queued scans grouped by priority' do
                low    = queue.push( url: target, priority: -1 )
                high   = queue.push( url: target, priority: 1 )
                medium = queue.push( url: target, priority: 0 )

                get url
                expect(response_code).to eq 200
                expect(response_data.to_a).to eq({
                    '1'  => [high],
                    '0'  => [medium],
                    '-1' => [low]
                }.to_a)
            end
        end

        context 'when no Queue has been set' do
            it 'returns 501' do
                get url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end

    describe 'POST /queue' do
        let(:tpl_url) { '/queue' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'pushes the scan to the Queue' do
                post url, url: target, priority: 9
                expect(response_code).to eq 200

                id = response_data['id']

                expect(queue.get(id)).to eq(
                    'options' => {
                        'url' => target
                    },
                    'priority' => 9
                )
            end

            context 'when given invalid options' do
                it 'returns a 500' do
                    post url, stuff: target

                    expect(response_code).to eq 500
                    expect(response_data['error']).to eq 'Arachni::RPC::Exceptions::RemoteException'
                    expect(response_data).to include 'backtrace'
                end
            end
        end

        context 'when no Queue has been set' do
            it 'returns 501' do
                get url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end

    describe 'GET /queue/url' do
        let(:tpl_url) { '/queue/url' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'returns its URL' do
                get url
                expect(response_code).to eq 200
                expect(response_data).to eq queue.url
            end
        end

        context 'when no Queue has been set' do
            it 'returns 501' do
                get url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end

    describe 'PUT /queue/url' do
        let(:tpl_url) { '/queue/url' }


        it 'sets the Queue URL' do
            put url, queue.url
            expect(response_code).to eq 200
        end

        context 'when given an invalid URL' do
            it 'returns 500' do
                put url, 'localhost:393939'

                expect(response_code).to eq 500
                expect(response_data['error']).to eq 'Arachni::RPC::Exceptions::ConnectionError'
                expect(response_data['description']).to include 'Connection closed [Connection refused - connect(2) for'
            end
        end
    end

    describe 'DELETE /queue/url' do
        let(:tpl_url) { '/queue/url' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'removes it' do
                delete url
                expect(response_code).to eq 200

                get '/queue/url'
                expect(response_code).to eq 501
            end
        end

        context 'when no Queue has been set' do
            it 'returns 501' do
                get url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end

    describe 'GET /queue/running' do
        let(:tpl_url) { '/queue/running' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'returns running scans' do
                get url
                expect(response_data.empty?).to be_truthy

                @id = queue.push( url: target )
                sleep 0.1 while queue.running.empty?

                get url
                expect(response_data.size).to be 1
                expect(response_data[@id]).to include 'url'
                expect(response_data[@id]).to include 'token'
                expect(response_data[@id]).to include 'pid'
            end
        end

        context 'when no Queue has been set' do
            it 'returns 501' do
                get url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end

    describe 'GET /queue/completed' do
        let(:tpl_url) { '/queue/completed' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'returns completed scans' do
                get url
                expect(response_data.empty?).to be_truthy

                @id = queue.push( url: target )
                sleep 0.1 while queue.completed.empty?

                get url
                expect(response_data.size).to be 1
                expect(File.exists? response_data[@id]).to be true
            end
        end

        context 'when no Queue has been set' do
            it 'returns 501' do
                get url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end

    describe 'GET /queue/failed' do
        let(:tpl_url) { '/queue/failed' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'returns failed scans' do
                get url
                expect(response_data.empty?).to be_truthy

                @id = queue.push( url: target )
                sleep 0.1 while queue.running.empty?
                SCNR::Engine::Processes::Manager.kill queue.running.values.first['pid']
                sleep 0.1 while queue.failed.empty?

                get url
                expect(response_data.size).to be 1
                expect(response_data[@id]['error']).to eq 'Arachni::RPC::Exceptions::ConnectionError'
                expect(response_data[@id]['description']).to include 'Connection closed [Connection refused - connect(2) for'
            end
        end

        context 'when no Queue has been set' do
            it 'returns 501' do
                get url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end

    describe 'GET /queue/size' do
        let(:tpl_url) { '/queue/size' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'returns the queue size' do
                get url
                expect(response_data).to eq 0

                10.times do
                    queue.push( url: target )
                end

                get url
                expect(response_data).to be 10
            end
        end

        context 'when no Queue has been set' do
            it 'returns 501' do
                get url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end

    describe 'DELETE /queue' do
        let(:tpl_url) { '/queue' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'empties the queue' do
                expect(queue.empty?).to be_truthy

                10.times do
                    queue.push( url: target )
                end

                expect(queue.any?).to be_truthy

                delete url
                expect(queue.empty?).to be_truthy
            end
        end

        context 'when no Queue has been set' do
            it 'returns 501' do
                get url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end

    describe 'GET /queue/:scan' do
        let(:tpl_url) { '/queue/%s' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'returns info for the Queued scan' do
                @id = queue.push( url: target )

                get url
                expect(response_code).to be 200
                expect(response_data).to eq({
                    'options' => {
                        'url' => target
                    },
                    'priority' => 0
                })
            end

            context 'when the scan could not be found' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    get url

                    expect(response_code).to eq 404
                    expect(response_data).to eq 'Scan not in Queue.'
                end
            end
        end

        context 'when no Queue has been set' do
            let(:id) { non_existent_id }

            it 'returns 501' do
                get url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end

    describe 'PUT /queue/:scan/detach' do
        let(:tpl_url) { '/queue/%s/detach' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'detaches the scan from the Queue' do
                @id = queue.push( url: target )
                sleep 0.1 while queue.running.empty?

                put url
                expect(response_code).to be 200
                expect(queue.running).to be_empty
                expect(queue.completed).to be_empty
                expect(queue.failed).to be_empty

                get '/scans'
                expect(response_code).to be 200
                expect(response_data.keys).to eq [@id]
            end

            context 'when the scan could not be found' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    put url

                    expect(response_code).to eq 404
                    expect(response_data).to eq 'Scan not in Queue.'
                end
            end
        end

        context 'when no Queue has been set' do
            let(:id) { non_existent_id }

            it 'returns 501' do
                put url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end

    describe 'DELETE /queue/:scan' do
        let(:tpl_url) { '/queue/%s' }

        context 'when a Queue has been set' do
            before do
                put '/queue/url', queue.url
            end

            it 'removes the scan from the Queue' do
                @id = queue.push( url: target )

                expect(queue.any?).to be_truthy

                delete url

                expect(response_code).to be 200
                expect(queue.empty?).to be_truthy
            end

            context 'when the scan could not be found' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    delete url

                    expect(response_code).to eq 404
                    expect(response_data).to eq 'Scan not in Queue.'
                end
            end
        end

        context 'when no Queue has been set' do
            let(:id) { non_existent_id }

            it 'returns 501' do
                delete url

                expect(response_code).to eq 501
                expect(response_data).to eq 'No Queue has been set.'
            end
        end
    end
end
