require 'spec_helper'

class Subject
    include SCNR::Engine::UI::Output
    include SCNR::Engine::Utilities
end

describe SCNR::Engine::Utilities do

    subject { Subject.new }

    let(:response) { Factory[:response] }
    let(:page) { Factory[:page] }

    describe '#caller_name' do
        it 'returns the filename of the caller' do
            expect(subject.caller_name).to eq('example')
        end
    end

    describe '#caller_path' do
        it 'returns the filepath of the caller' do
            expect(subject.caller_path).to eq(Kernel.caller.first.match( /^(.+):\d/ )[1])
        end
    end

    {
        forms_from_response:     [SCNR::Engine::Element::Form, :from_response],
        forms_from_parser:     [SCNR::Engine::Element::Form, :from_parser],
        form_encode:             [SCNR::Engine::Element::Form, :encode],
        form_decode:             [SCNR::Engine::Element::Form, :decode],
        request_parse_body:      [SCNR::Engine::HTTP::Request, :parse_body],
        links_from_response:     [SCNR::Engine::Element::Link, :from_response],
        links_from_parser:     [SCNR::Engine::Element::Link, :from_parser],
        cookies_from_response:   [SCNR::Engine::Element::Cookie, :from_response],
        cookies_from_parser:   [SCNR::Engine::Element::Cookie, :from_parser],
        cookies_from_file:       [SCNR::Engine::Element::Cookie, :from_file],
        cookie_encode:           [SCNR::Engine::Element::Cookie, :encode],
        cookie_decode:           [SCNR::Engine::Element::Cookie, :decode],
        parse_set_cookie:        [SCNR::Engine::Element::Cookie, :parse_set_cookie],
        page_from_response:      [SCNR::Engine::Page, :from_response],
        page_from_url:           [SCNR::Engine::Page, :from_url],
        html_encode:             [CGI, :escapeHTML],
        html_escape:             [CGI, :escapeHTML],
        uri_parse:               [SCNR::Engine::URI, :parse],
        uri_rewrite:             [SCNR::Engine::URI, :rewrite],
        uri_parse_query:         [SCNR::Engine::URI, :parse_query],
        uri_encode:              [SCNR::Engine::URI, :encode],
        uri_decode:              [SCNR::Engine::URI, :decode],
        normalize_url:           [SCNR::Engine::URI, :normalize],
        to_absolute:             [SCNR::Engine::URI, :to_absolute],
        full_and_absolute_url?:  [SCNR::Engine::URI, :full_and_absolute?]
    }.each do |m, (klass, delegated)|
        describe "##{m}" do
            it "delegates to #{klass}.#{delegated}" do
                ret = :blah

                allow(klass).to receive(delegated){ ret }
                expect(subject.send( m, 'stuff' )).to eq(ret)
            end
        end
    end

    describe '#get_path' do
        it "delegates to #{SCNR::Engine::URI}#get_path" do
            expect(subject.get_path( 'http://test.com/stuff/?blah' )).to eq 'http://test.com/stuff/'
        end
    end

    {
        :redundant_path?  => :redundant?,
        :path_in_domain?  => :in_domain?,
        :path_too_deep?   => :too_deep?,
        :exclude_path?    => :exclude?,
        :include_path?    => :include?,
        :follow_protocol? => :follow_protocol?,
    }.each do |k, v|
        describe "##{k}" do
            it "delegates to #{SCNR::Engine::URI::Scope}##{v}" do
                allow_any_instance_of(SCNR::Engine::URI::Scope).to receive(v) { :stuff }
                expect(subject.send( k, 'http://url/' )).to eq(:stuff)
            end
        end
    end

    describe '#port_available?' do
        context 'when a port is available' do
            it 'returns true' do
                expect(subject.port_available?( 7777 )).to be_truthy
            end
        end

        context 'when a port is not available' do
            it 'returns true' do
                s = TCPServer.new( "127.0.0.1", 7777 )
                expect(subject.port_available?( 7777 )).to be_falsey
                s.close
            end
        end
    end

    describe '#skip_page?' do
        it "delegates to #{SCNR::Engine::Page::Scope}#out?" do
            allow_any_instance_of(SCNR::Engine::Page::Scope).to receive(:out?) { :stuff }
            expect(subject.skip_page?( page )).to eq(:stuff)
        end
    end

    describe '#skip_response?' do
        it "delegates to #{SCNR::Engine::HTTP::Response::Scope}#out?" do
            allow_any_instance_of(SCNR::Engine::HTTP::Response::Scope).to receive(:out?) { :stuff }
            expect(subject.skip_response?( response )).to eq(:stuff)
        end
    end

    describe '#skip_resource?' do
        context 'when passed a' do
            context 'Engine::HTTP::Response' do
                context 'and #skip_response? returns' do
                    context 'true' do
                        it 'returns true' do
                            allow(subject).to receive(:skip_response?){ true }
                            expect(subject.skip_resource?( response )).to be_truthy
                        end
                    end

                    context 'false' do
                        it 'returns false' do
                            allow(subject).to receive(:skip_response?){ false }
                            expect(subject.skip_resource?( response )).to be_falsey
                        end
                    end
                end
            end

            context 'Engine::Page' do
                context 'and #skip_page? returns' do
                    context 'true' do
                        it 'returns true' do
                            allow(subject).to receive(:skip_page?){ true }
                            expect(subject.skip_resource?( page )).to be_truthy
                        end
                    end

                    context 'false' do
                        it 'returns false' do
                            allow(subject).to receive(:skip_page?){ false }
                            expect(subject.skip_resource?( page )).to be_falsey
                        end
                    end
                end
            end

            context 'String' do
                context 'and #skip_path? returns' do
                    context 'true' do
                        it 'returns true' do
                            allow(subject).to receive(:skip_path?){ true }
                            expect(subject.skip_resource?( 'stuff' )).to be_truthy
                        end
                    end

                    context 'false' do
                        it 'returns false' do
                            allow(subject).to receive(:skip_path?){ false }
                            expect(subject.skip_resource?( 'stuff' )).to be_falsey
                        end
                    end
                end
            end
        end
    end

    describe '#random_seed' do
        it 'returns a random string' do
            expect(subject.random_seed).to be_kind_of String
        end
    end

    describe '#seconds_to_hms' do
        it 'converts seconds to HOURS:MINUTES:SECONDS' do
            expect(subject.seconds_to_hms( 0 )).to eq('00:00:00')
            expect(subject.seconds_to_hms( 1 )).to eq('00:00:01')
            expect(subject.seconds_to_hms( 60 )).to eq('00:01:00')
            expect(subject.seconds_to_hms( 60*60 )).to eq('01:00:00')
            expect(subject.seconds_to_hms( 60*60 + 60 + 1 )).to eq('01:01:01')
        end
    end

    describe '#hms_to_seconds' do
        it 'converts seconds to HOURS:MINUTES:SECONDS' do
            expect(subject.hms_to_seconds( '00:00:00' )).to eq(0)
            expect(subject.hms_to_seconds( '00:00:01' )).to eq(1)
            expect(subject.hms_to_seconds( '00:01:00' )).to eq(60)
            expect(subject.hms_to_seconds( '01:00:00' )).to eq(60*60)
            expect(subject.hms_to_seconds( '01:01:01')).to eq(60 * 60 + 60 + 1)
        end
    end

    describe '#exception_jail' do
        context 'when no error occurs' do
            it 'returns the return value of the block' do
                expect(subject.exception_jail { :stuff }).to eq(:stuff)
            end
        end

        context "when a #{RuntimeError} occurs" do
            context 'and raise_exception is' do
                context 'default' do
                    it 're-raises the exception' do
                        expect do
                            subject.exception_jail { raise }
                        end.to raise_error RuntimeError
                    end
                end

                context 'true' do
                    it 're-raises the exception' do
                        expect do
                            subject.exception_jail( true ) { raise }
                        end.to raise_error RuntimeError
                    end
                end

                context 'false' do
                    it 'returns nil' do
                        expect(subject.exception_jail( false ) { raise }).to be_nil
                    end
                end
            end
        end

        context "when an #{Exception} occurs" do
            context 'and raise_exception is' do
                context 'default' do
                    it 'does not rescue it' do
                        expect do
                            subject.exception_jail { raise Exception }
                        end.to raise_error Exception
                    end
                end

                context 'true' do
                    it 'does not rescue it' do
                        expect do
                            subject.exception_jail( true ) { raise Exception }
                        end.to raise_error Exception
                    end
                end

                context 'false' do
                    it 'does not rescue it' do
                        expect do
                            subject.exception_jail( false ) { raise Exception }
                        end.to raise_error Exception
                    end
                end
            end
        end
    end

end
