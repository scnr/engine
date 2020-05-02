shared_examples_for 'browser_engine' do

    let(:browser) do
        SCNR::Engine::Browser.new( options.merge( engine: described_class.name ) )
    end
    let(:options) { {} }
    subject { browser.engine }

    it 'supports HTTPS' do
        url = web_server_url_for( :browser_https )

        browser.start_capture
        pages = browser.load( url, take_snapshot: true ).flush_pages

        pages_should_have_form_with_input( pages, 'ajax-token' )
        pages_should_have_form_with_input( pages, 'by-ajax' )
    end

    context 'when the browser dies' do
        it 'kills the lifeline too' do
            SCNR::Engine::Processes::Manager.kill subject.pid
            expect(SCNR::Engine::Processes::Manager.alive?(subject.lifeline_pid)).to be_falsey
        end
    end

    context 'when the lifeline dies' do
        it 'kills the browser too' do
            SCNR::Engine::Processes::Manager.kill subject.lifeline_pid
            expect(SCNR::Engine::Processes::Manager.alive?(subject.pid)).to be_falsey
        end
    end

    describe '#initialize' do
        describe ':width' do
            it "defaults to #{SCNR::Engine::OptionGroups::Device}#width" do
                expect(subject.window_width).to eq(SCNR::Engine::Options.device.width)
            end

            context 'when given' do
                let(:width) { 400 }
                let(:options) { { width: width } }

                it 'sets the window width' do
                    expect(subject.window_width).to eq(width)
                end
            end
        end

        describe ':height' do
            it "defaults to #{SCNR::Engine::OptionGroups::Device}#height" do
                expect(subject.window_height).to eq(SCNR::Engine::Options.device.height)
            end

            context 'when given' do
                let(:height) { 200 }
                let(:options) { { height: height } }

                it 'sets the window height' do
                    expect(subject.window_height).to eq(height)
                end
            end
        end

        describe ':user_agent' do
            it "defaults to #{SCNR::Engine::OptionGroups::Device}#user_agent" do
                expect(subject.user_agent).to eq(SCNR::Engine::Options.device.user_agent)
            end

            context 'when given' do
                let(:user_agent) { 'Blah' }
                let(:options) { { user_agent: user_agent } }

                it 'sets the user-agent' do
                    expect(subject.user_agent).to eq(user_agent)
                end
            end
        end

        describe ':pixel_ratio' do
            it "defaults to #{SCNR::Engine::OptionGroups::Device}#pixel_ratio" do
                expect(subject.pixel_ratio).to eq(SCNR::Engine::Options.device.pixel_ratio)
            end

            context 'when given' do
                let(:pixel_ratio) { 2.5 }
                let(:options) { { pixel_ratio: pixel_ratio } }

                it 'sets the pixel ratio' do
                    expect(subject.pixel_ratio).to eq(pixel_ratio)
                end
            end
        end

        describe ':touch' do
            it "defaults to #{SCNR::Engine::OptionGroups::Device}#touch" do
                expect(subject.touch?).to eq(SCNR::Engine::Options.device.touch?)
            end

            context 'when given' do
                let(:options) { { touch: touch } }

                context 'true' do
                    let(:touch) { true }

                    it 'enables touch support' do
                        expect(subject).to be_touch
                    end
                end

                context 'false' do
                    let(:touch) { false }

                    it 'enables touch support' do
                        expect(subject).to_not be_touch
                    end
                end
            end
        end

        context 'when the spawn fails' do
            it "raises #{SCNR::Engine::Browser::Engines::Error::Spawn}"

            context 'due to a missing executable' do
                it "raises #{SCNR::Engine::Browser::Engines::Error::MissingExecutable}"
            end
        end
    end

    describe '#reboot' do
        it 'kills the process'

        it 'kills the lifeline'

        it 'starts a new process'

        it 'starts a new lifeline'

        it 'provides a new Selenium instance'

        it 'provides a new Watir instance'
    end

    describe '#shutdown' do
        it 'kills the process'
        it 'kills the lifeline'
    end

    describe '#watir' do
        it 'provides access to the Watir::Browser API' do
            expect(subject.watir).to be_kind_of Watir::Browser
        end
    end

    describe '#selenium' do
        it 'provides access to the Selenium::WebDriver::Driver API' do
            expect(subject.selenium).to be_kind_of Selenium::WebDriver::Driver
        end
    end

    describe '#refresh' do
        it 'provides a new Selenium instance'

        it 'provides a new Watir instance'
    end

    describe '#alive?' do
        context 'when the lifeline is alive' do
            it 'returns true' do
                expect(SCNR::Engine::Processes::Manager.alive?(subject.lifeline_pid)).to be_truthy
                expect(subject).to be_alive
            end
        end

        context 'when the browser is dead' do
            it 'returns false' do
                SCNR::Engine::Processes::Manager.kill subject.pid

                expect(subject).to_not be_alive
            end
        end

        context 'when the lifeline is dead' do
            it 'returns false' do
                SCNR::Engine::Processes::Manager << subject.pid
                SCNR::Engine::Processes::Manager.kill subject.lifeline_pid

                expect(subject).to_not be_alive
            end
        end
    end

    describe '#window_width' do
        it 'returns the window width'
    end

    describe '#window_height' do
        it 'returns the window height'
    end

end
