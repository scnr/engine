require 'spec_helper'

require SCNR::Engine::Options.paths.lib + 'rpc/client/instance'
require SCNR::Engine::Options.paths.lib + 'rpc/server/instance'

describe SCNR::Engine::RPC::Server::ActiveOptions do
    let(:instance) { instance_spawn }
    
    describe '#set' do
        it 'sets options by hash' do
            expect(instance.cookies).to be_empty

            opts = {
                'url'   =>  'http://blah.com',
                'scope' =>  {
                    'exclude_path_patterns'   => [ 'exclude me' ],
                    'include_path_patterns'   => [ 'include me' ],
                    'redundant_path_patterns' => { 'redundant' => 3 },
                },
                'datastore' => { 'key' => 'val' },
                'http'      => {
                    'cookies'       => {
                        'name'  => 'value',
                        'name2' => 'value2'
                    },
                    'cookie_string' => 'name3=value3,name4=value4'
                }
            }

            instance.options.set( opts )
            h = instance.options.to_h

            expect(h['url'].to_s).to eq(SCNR::Engine::Utilities.normalize_url( opts['url'] ))
            expect(h['scope']['exclude_path_patterns']).to eq( opts['scope']['exclude_path_patterns'] )
            expect(h['scope']['include_path_patterns']).to eq( opts['scope']['include_path_patterns'] )
            expect(h['scope']['redundant_path_patterns']).to eq( opts['scope']['redundant_path_patterns'] )

            expect(h['datastore']['key']).to eq(opts['datastore']['key'])

            expect(instance.cookies.map { |c| SCNR::Engine::Cookie.from_rpc_data c }).to eq([
                SCNR::Engine::Cookie.new( url: opts['url'], inputs: { 'name'  => 'value' } ),
                SCNR::Engine::Cookie.new( url: opts['url'], inputs: { 'name2'  => 'value2' } ),
                SCNR::Engine::Cookie.new( url: opts['url'], inputs: { 'name3'  => 'value3' } ),
                SCNR::Engine::Cookie.new( url: opts['url'], inputs: { 'name4'  => 'value4' } )
            ])
        end

        context 'when the scan is in progress' do
            before :each do
                instance.scan( url: url )
            end

            let(:url) { web_server_url_for( :framework_multi ) }

            it 'resets HTTP options' do
                opts = {
                    'http' => {
                        'request_concurrency' => 1111
                    }
                }
                instance.options.set( opts )

                expect(instance.progress[:statistics][:http][:max_concurrency]).to eq 1111
            end

            it 'removes out of scope sitemap entries' do
                sleep 1 while instance.sitemap.size < 10

                opts = {
                    'scope' => {
                        'exclude_path_patterns' => [
                            '.'
                        ]
                    }
                }
                instance.options.set( opts )

                expect(instance.sitemap).to be_empty
            end

            it 'pushes new extend paths' do
                opts = {
                    'scope' => {
                        'extend_paths' => [
                            '/my/path/1',
                            '/my/path/2'
                        ]
                    }
                }
                instance.options.set( opts )

                sleep 1 while instance.busy?

                expect(instance.sitemap).to include "#{url}/my/path/1"
                expect(instance.sitemap).to include "#{url}/my/path/2"
            end
        end
    end
end
