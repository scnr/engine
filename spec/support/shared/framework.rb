shared_examples_for 'framework' do

    before( :each ) do
        SCNR::Engine::Options.url = url

        SCNR::Engine::Options.paths.reporters = fixtures_path + '/reporters/manager_spec/'
        SCNR::Engine::Options.paths.checks    = fixtures_path + '/signature_check/'
    end

    subject { SCNR::Engine::Framework.new }
    let(:url) { web_server_url_for( :auditor ) }
    let(:f_url) { web_server_url_for( :framework ) }
end
