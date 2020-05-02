require 'spec_helper'

describe SCNR::Engine::Element::Body do
    it_should_behave_like 'element'
    it_should_behave_like 'with_auditor'

    subject do
        described_class.new( page.url )
    end
    let(:url) { web_server_url_for( :body ) }
    let(:page) { SCNR::Engine::Page.from_url( url ) }
    let(:framework) { SCNR::Engine::Framework.new }
    let(:auditor) { Auditor.new( page, framework ) }
    let(:auditable) do
        s = subject.dup
        s.auditor = auditor
        s
    end

    let(:valid_pattern) { /match/i }
    let(:invalid_pattern) { /will not match/ }

    describe '#match_and_log' do
        context 'when defaulting to current page' do
            context 'and it matches the given pattern' do
                it 'logs an issue' do
                    auditable.match_and_log( valid_pattern )

                    logged_issue = SCNR::Engine::Data.issues.sort.first
                    expect(logged_issue).to be_truthy

                    expect(logged_issue.vector.url).to eq(SCNR::Engine::Utilities.normalize_url( url ))
                    expect(logged_issue.vector.class).to eq(SCNR::Engine::Element::Body)
                    expect(logged_issue.signature).to eq(valid_pattern.source)
                    expect(logged_issue.proof).to eq('Match')
                    expect(logged_issue.trusted).to be_truthy
                end
            end

            context 'and it does not matche the given pattern' do
                it 'does not log an issue' do
                    auditable.match_and_log( invalid_pattern )
                    expect(SCNR::Engine::Data.issues).to be_empty
                end
            end
        end
    end

    describe '#dup' do
        it 'duplicates self' do
            body = auditable.dup
            expect(body).to eq(auditable)
            expect(body.object_id).not_to eq(auditable)
        end
    end

end
