require 'sinatra'
require 'sinatra/contrib'

set :logging, false
set :host_authorization, { permitted_hosts: [] }

get '/' do
    <<-EOHTML
    <a href='?input=blah'>Inject here</a>
    #{params[:input]}
EOHTML
end
