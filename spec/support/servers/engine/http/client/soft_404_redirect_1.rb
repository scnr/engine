require 'sinatra'
require 'ap'

class Soft404Redirect_1 < Sinatra::Application

    @@redirect_url ||= nil

    get '/set-redirect' do
        @@redirect_url ||= params[:url]
    end

    get '/test/index.html' do
        response.headers['Content-Type'] = 'text/html'
        "some content here for index page"
    end

    get '*' do
        response.headers['Content-Type'] = 'text/html'
        redirect "#{@@redirect_url}/error/index.html", 302
    end

    run!
end
