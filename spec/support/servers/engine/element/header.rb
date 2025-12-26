require 'yaml'
require 'sinatra'
require 'sinatra/streaming'

set :host_authorization, { permitted_hosts: [] }
set :logging, false

IGNORE = %w(HTTP_VERSION HTTP_HOST HTTP_ACCEPT_ENCODING HTTP_USER_AGENT
    HTTP_ACCEPT HTTP_ACCEPT_LANGUAGE HTTP_X_SCNR_ENGINE_SCAN_SEED HTTP_AUTHORIZATION
    HTTP_UPGRADE HTTP_HTTP2_SETTINGS HTTP_CONNECTION)

def submitted
    h = {}
    env.select { |k, v| k.start_with?( 'HTTP_' ) && !IGNORE.include?( k ) }.each do |k, v|
        h[k.gsub( 'HTTP_', '' ).downcase] = v
    end
    h
end

get '/' do
    submitted.to_s
end

get '/submit' do
    submitted.to_hash.to_yaml
end

get '/submit/buffered' do
    stream do |out|
        2_000.times do |i|
            out.print "Blah"
        end

        out.print 'START_PARAMS'
        out.print submitted.to_hash.to_yaml
        out.print 'END_PARAMS'

        2_000.times do |i|
            out.print "Blah"
        end
    end
end

get '/submit/line_buffered' do
    stream do |out|
        2_000.times do |i|
            out.puts "Blah"
        end

        out.puts 'START_PARAMS'
        out.puts submitted.to_hash.to_yaml
        out.puts 'END_PARAMS'

        2_000.times do |i|
            out.puts "Blah"
        end
    end
end

get '/sinks/body' do
    submitted['active']
end

get '/sinks/header/name' do
    headers submitted['active'] => '1'
    ''
end

get '/sinks/header/value' do
    headers 'X-Stuff' => submitted['active']
    ''
end

get '/sinks/blind' do
    "Nada #{rand(999999)}"
end

get '/sinks/active' do
    if submitted['active'] == 'value1'
        'Stuff here blah blah'
    else
        'Different stuff here blah blah'
    end
end
