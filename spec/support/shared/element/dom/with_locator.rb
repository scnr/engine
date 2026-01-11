shared_examples_for 'with_locator' do

    describe '#locator' do
        it "returns a #{SCNR::Engine::Browser::ElementLocator}" do
            called = false
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page

                expect(subject.locator).to be_kind_of SCNR::Engine::Browser::ElementLocator

                element = browser.selenium.find_element( :css, subject.locator.css )
                expect(element).to be_kind_of Selenium::WebDriver::Element
                expect(element.opening_tag.split(/./).sort).to eq subject.locator.to_s.split(/./).sort
                called = true
            end

            subject.auditor.browser_pool.wait
            expect(called).to be_truthy
        end
    end

end
