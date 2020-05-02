Factory.define :request do
    SCNR::Engine::HTTP::Request.new(
        url:    'http://a-url.com/',
        method: :get,
        headers: {
            'req-header-name' => 'req header value'
        }
    )
end
