require 'sinatra'

put '/SCNR::Engine-*' do
    body = request.body.read
    self.class.get( env['REQUEST_PATH'] ) { body }
    status 201
end
