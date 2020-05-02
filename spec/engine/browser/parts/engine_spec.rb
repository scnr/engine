require 'spec_helper'

describe SCNR::Engine::Browser::Parts::Engine do
    include_examples 'browser'

    describe '#initialize' do
        before :each do
            subject.load url
        end

        describe ':engine' do
            it 'sets the engine to use'

            context 'when an unknown engine is given' do
                it "fails with #{described_class::Error::UnknownEngine}"
            end
        end

        describe ':width' do
            context 'when given' do
                let(:options) { { width: width } }
                let(:width) { 400 }

                it 'sets the window width' do
                    expect(subject.window_width).to eq(width)
                end
            end

            it 'defaults to 1600' do
                expect(subject.window_width).to eq(1600)
            end
        end

        describe ':height' do
            context 'when given' do
                let(:options) { { height: height } }
                let(:height) { 200 }

                it 'sets the window height' do
                    expect(subject.window_height).to eq(height)
                end
            end

            it 'defaults to 1200' do
                expect(subject.window_height).to eq(1200)
            end
        end
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

    describe '#source' do
        it 'returns the page source without the JS env modifications'
    end

    describe '#real_source' do
        it 'returns the page source with the JS env modifications'
    end

    describe '#source_with_line_numbers' do
        it 'prefixes each source code line with a number' do
            subject.load url

            lines = subject.source.lines.to_a

            expect(lines).to be_any
            subject.source_with_line_numbers.lines.each.with_index do |l, i|
                expect(l).to eq("#{i+1} - #{lines[i]}")
            end
        end
    end

end
