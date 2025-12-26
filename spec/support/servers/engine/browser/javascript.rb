require 'sinatra'
require 'sinatra/contrib'

set :host_authorization, { permitted_hosts: [] }


get '/' do
    <<HTML
HTML
end
