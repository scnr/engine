require 'sinatra'

get '/' do
    <<-EOHTML
    <html>
        <body>
            <a href='/dom/#/param/some-name'>DOM link</a>
        </body>
    </html>
    EOHTML
end

get '/inputtable' do
    <<-EOHTML
    <html>
        <body>
            <a href='/dom/#/input1/value1/input2/value2'>DOM link</a>
        </body>
    </html>
    EOHTML
end

get '/dom/' do
    <<-EOHTML
    <html>
        <script>
            function getQueryVariable(variable) {
                var splits = window.location.hash.split('/');
                return decodeURI( splits[splits.indexOf( variable ) + 1] );
            }
        </script>

        <body>
            <div id="container">
            </div>

            <script>
                document.getElementById('container').innerHTML = getQueryVariable('param');
            </script>
        </body>
    </html>
    EOHTML
end

get '/link/sinks/body' do
    <<-EOHTML
    <html>
        <body>
            <a href='/sinks/body#/active/value1/blind/value2'>DOM link</a>
        </body>
    </html>
    EOHTML
end

get '/sinks/body' do
    <<-EOHTML
    <html>
        <script>
            function getQueryVariable(variable) {
                var splits = window.location.hash.split('/');
                return decodeURI( splits[splits.indexOf( variable ) + 1] );
            }
        </script>

        <body>
            <a href='/dom/#/test/?active=value1&blind=value2'>DOM link</a>

            <div id="container">
            </div>

            <script>
                document.getElementById('container').innerHTML = getQueryVariable('active');
            </script>
        </body>
    </html>
    EOHTML
end

get '/link/sinks/blind' do
    <<-EOHTML
    <html>
        <body>
            <a href='/sinks/blind#/active/value1/blind/value2'>DOM link</a>
        </body>
    </html>
    EOHTML
end

get '/sinks/blind' do
    <<-EOHTML
    <html>
        <script>
            function getQueryVariable(variable) {
                var splits = window.location.hash.split('/');
                return decodeURI( splits[splits.indexOf( variable ) + 1] );
            }
        </script>

        <body>
            <div id="container">
            </div>

            <script>
                document.getElementById('container').innerHTML = getQueryVariable('blah');
            </script>
        </body>
    </html>
    EOHTML
end

get '/link/sinks/active' do
    <<-EOHTML
    <html>
        <body>
            <a href='/sinks/active#/active/value1/blind/value2'>DOM link</a>
        </body>
    </html>
    EOHTML
end

get '/sinks/active' do
    <<-EOHTML
    <html>
        <script>
            function getQueryVariable(variable) {
                var splits = window.location.hash.split('/');
                return decodeURI( splits[splits.indexOf( variable ) + 1] );
            }
        </script>

        <body>
            <a href='/dom/#/test/?active=value1&blind=value2'>DOM link</a>

            <script>
                getQueryVariable('active');
            </script>
        </body>
    </html>
    EOHTML
end
