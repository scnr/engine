shared_examples_for 'javascript' do
    let(:dom_monitor_url) { SCNR::Engine::Utilities.normalize_url( web_server_url_for( :dom_monitor ) ) }
    let(:taint_tracer_url) { SCNR::Engine::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) }
    let(:browser) { SCNR::Engine::Browser.new }
    subject { browser.javascript }
end
