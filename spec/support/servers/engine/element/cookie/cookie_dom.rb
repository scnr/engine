require 'sinatra'
require 'sinatra/contrib'

set :host_authorization, { permitted_hosts: [] }

get '/' do
    <<-EOHTML
<html>
    <head>
        <title></title>
    </head>

    <body>
        <div id='container'>
        </div>

        <script>
            document.getElementById('container').innerHTML = decodeURIComponent(document.cookie);
        </script>
    </body>
</html>
    EOHTML
end

get '/sinks/body' do
    <<-EOHTML
<html>
    <head>
        <title></title>
    </head>

    <body>
        <div id='container'>
        </div>

        <script>
            document.getElementById('container').innerHTML = decodeURIComponent(document.cookie);
        </script>
    </body>
</html>
    EOHTML
end

get '/sinks/blind' do
    "Nada #{rand(999999)}"
end

get '/sinks/active' do
    <<-EOHTML
<html>
    <body>
        <script>
            decodeURIComponent( document.cookie );
        </script>
    </body>
</html>
    EOHTML
end
