require 'json'
require 'sinatra'
require 'sinatra/streaming'

def submitted
    JSON.load request.body.read
end

post '/submit' do
    request.body.read
end

post '/submit/buffered' do
    stream do |out|
        2_000.times do |i|
            out.print "Blah"
        end

        out.print 'START_PARAMS'
        out.print request.body.read
        out.print 'END_PARAMS'

        2_000.times do |i|
            out.print "Blah"
        end
    end
end

post '/submit/line_buffered' do
    stream do |out|
        2_000.times do |i|
            out.puts "Blah"
        end

        out.puts 'START_PARAMS'
        out.puts request.body.read
        out.puts 'END_PARAMS'

        2_000.times do |i|
            out.puts "Blah"
        end
    end
end

post '/sinks/body' do
    submitted['active']
end

post '/sinks/header/name' do
    headers submitted['active'] => '1'
    ''
end

post '/sinks/header/value' do
    headers 'X-Stuff' => submitted['active']
    ''
end

post '/sinks/blind' do
    "Nada #{rand(999999)}"
end

post '/sinks/active' do
    if submitted['active'] == 'value1'
        'Stuff here blah blah'
    else
        'Different stuff here blah blah'
    end
end
