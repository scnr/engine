shared_examples_for 'fingerprinter' do
    include_examples 'component'

    def check_platforms( page )
        platforms.each do |p|
            expect(platforms_for( page )).to include p
        end
    end

    def platforms_for( page )
        SCNR::Engine::Platform::Manager.reset
        expect(page.platforms).to be_empty

        described_class.new( page ).run
        page.platforms
    end

end
