require 'spec_helper'

describe SCNR::Engine::Browser do
    include_examples 'browser'

    describe '#initialize' do
        describe ':ignore_scope' do
            context 'true' do
                let(:options) { { ignore_scope: true } }

                it 'ignores scope restrictions' do
                    SCNR::Engine::Options.scope.exclude_path_patterns << /sleep/

                    subject.load url + '/ajax_sleep'
                    expect(subject.to_page).to be_truthy
                end
            end

            context 'false' do
                let(:options) { { ignore_scope: false } }

                it 'enforces scope restrictions' do
                    SCNR::Engine::Options.scope.exclude_path_patterns << /sleep/

                    subject.load url + '/ajax_sleep'
                    expect(subject.to_page.code).to eq(0)
                end
            end

            context ':default' do
                it 'enforces scope restrictions' do
                    SCNR::Engine::Options.scope.exclude_path_patterns << /sleep/

                    subject.load url + '/ajax_sleep'
                    expect(subject.to_page.code).to eq(0)
                end
            end
        end
    end

end
