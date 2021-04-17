require 'sinatra'
require 'yaml'

get '/' do
    <<-EOHTML
<html>
    <head>
        <title></title>
    </head>

    <body>#{env['REQUEST_METHOD'].downcase + params.to_s}</body>
</html>
    EOHTML
end

get '/submit' do
    <<-EOHTML
<html>
    <head>
        <title></title>
    </head>

    <body>#{Hash[params.to_hash].to_yaml}</body>
</html>
    EOHTML
end

get '/form' do
    <<-EOHTML
<html>
    <body>
        <form action="/submit">
            <input name="param"/>
        </fom>
    </body>
</html>
    EOHTML
end

get '/form/inputtable' do
    <<-EOHTML
<html>
    <body>
        <form action="/submit">
            <input name="input1"/>
            <input name="input2"/>
        </fom>
    </body>
</html>
    EOHTML
end

get '/form/with_sinks' do
    <<-EOHTML
<html>
    <body>
        <form action="">
            <input name="active"/>
            <input name="blind"/>
        </fom>
    </body>
</html>
    EOHTML
end

get '/sinks/body' do
    <<-EOHTML
<html>
    <body>
        <form onsubmit="return submit1()">
            <input id="active" name="active"/>
            <input name="blind"/>
        </fom>

        <div id="container"></div>

        <script>
            function submit1() {
                document.getElementById('container').innerHTML = document.getElementById('active').value;
                return false;
            }
        </script>
    </body>
</html>
    EOHTML
end

get '/sinks/blind' do
    <<-EOHTML
<html>
    <body>
        <form onsubmit="return submit1()">
            <input id="name" name="active"/>
            <input name="blind"/>
        </fom>

        <script>
            function submit1() {
                return false;
            }
        </script>
    </body>
</html>
    EOHTML
end

get '/sinks/active' do
    <<-EOHTML
<html>
    <body>
        <form onsubmit="return submit1()">
            <input id="active" name="active"/>
            <input name="blind"/>
        </fom>

        <script>
            function process( v ) {}
            function submit1() {
                process( document.getElementById('active').value );
                return false;
            }
        </script>
    </body>
</html>
    EOHTML
end
