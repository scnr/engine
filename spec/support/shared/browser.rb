shared_examples_for 'browser' do

    before( :each ) do
        clear_hit_count
    end

    let(:url) { root_url }
    let(:root_url) { SCNR::Engine::Utilities.normalize_url( web_server_url_for( :browser ) ) }
    let(:options) { {} }
    let(:subject) { SCNR::Engine::Browser.new( options ) }
    let(:ua) { SCNR::Engine::Options.device.user_agent }

    def transitions_from_array( transitions )
        dom_url = subject.dom_url

        transitions.map do |t|
            element, event = t.first.to_a

            options = {}
            if element == :page && event == :load
                options.merge!( url: dom_url, cookies: {} )
            end

            if element.is_a? Hash
                element = SCNR::Engine::Browser::ElementLocator.new( element )
            end

            SCNR::Engine::Page::DOM::Transition.new( element, event, options ).complete
        end
    end

    def hit_count
        Typhoeus::Request.get( "#{url}/hit-count" ).body.to_i
    end

    def image_hit_count
        Typhoeus::Request.get( "#{url}/image-hit-count" ).body.to_i
    end

    def clear_hit_count
        Typhoeus::Request.get( "#{url}/clear-hit-count" )
    end

end
