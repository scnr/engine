require 'sinatra'

set :host_authorization, { permitted_hosts: [] }

get '/' do
    'Match this!'
end
