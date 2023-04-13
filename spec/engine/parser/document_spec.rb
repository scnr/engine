require 'spec_helper'

describe SCNR::Engine::Parser::Document do
    let(:options) do
        {}
    end
    subject { SCNR::Engine::Parser.parse( html, options ) }
    let(:html) do
        <<-EOHTML
        <html>
            <div id="my-id">
                <!-- My comment -->
                <p class="my-class">
                    <a href="/stuff">Stuff</a>
                </p>

                My text
            </div>
        </html>
        EOHTML
    end

    describe '.parse' do
        describe 'filter', if: defined?( SCNR::Engine::Parser::Ext::Document ) do
            subject { described_class.parse html, filter }

            context 'default' do
                subject { described_class.parse html }
                let(:html) do
                    <<-EOHTML
                <html>
                    <form>
                        <span>
                            My text
                            <!-- My comment -->
                        </span>
                    </form>
                </html>
                    EOHTML
                end

                let(:expected) do
                    "<!DOCTYPE html>\n<html>\n    <form>\n        <span>\n            My text\n            <!-- My comment -->\n        </span>\n    </form>\n</html>\n\n"
                end

                it 'includes all elements' do
                    expect(subject.to_html).to eq expected
                end
            end

            context 'false' do
                let(:filter){ false }
                let(:html) do
                    <<-EOHTML
                <html>
                    <form>
                        <span>
                            My text
                            <!-- My comment -->
                        </span>
                    </form>
                </html>
                    EOHTML
                end

                let(:expected) do
                    "<!DOCTYPE html>\n<html>\n    <form>\n        <span>\n            My text\n            <!-- My comment -->\n        </span>\n    </form>\n</html>\n\n"
                end

                it 'includes all elements' do
                    expect(subject.to_html).to eq expected
                end
            end

            context 'true' do
                let(:filter){ true }

                context 'when removing nested elements' do
                    let(:html) do
                        <<-EOHTML
                    <html>
                        <form>
                            <span>
                                My text
                                <!-- My comment -->
                            </span>
                        </form>
                    </html>
                        EOHTML
                    end

                    let(:expected) do
                        "<!DOCTYPE html>\n<html>\n    <form>\n        <span>\n            <!-- My comment -->\n        </span>\n    </form>\n</html>\n\n"
                    end

                    it 'preserves the hierarchy' do
                        expect(subject.to_html).to eq expected
                    end
                end

                context 'when removing sequential elements' do
                    let(:html) do
                        <<-EOHTML
                    <html>
                        <form>
                            <p></p>
                            <!-- My comment -->
                            <div></div>
                            <!-- My other comment -->
                        </form>
                    </html>
                        EOHTML
                    end

                    let(:expected) do
                        "<!DOCTYPE html>\n<html>\n    <form>\n        <p>\n        </p>\n        <!-- My comment -->\n        <div>\n        </div>\n        <!-- My other comment -->\n    </form>\n</html>\n\n"
                    end

                    it 'preserves the sequence' do
                        expect(subject.to_html).to eq expected
                    end
                end

                context 'Comment' do
                    let(:html) do
                        <<-EOHTML
                        <html>
                            <!-- My comment -->
                        </html>
                        EOHTML
                    end

                    let(:expected) do
                        "<!DOCTYPE html>\n<html>\n    <!-- My comment -->\n</html>\n\n"
                    end

                    it 'includes it' do
                        expect(subject.to_html).to eq expected
                    end
                end

                context 'Text' do
                    let(:html) do
                        <<-EOHTML
                        <html>
                            Stuff
                        </html>
                        EOHTML
                    end

                    let(:expected) do
                        "<!DOCTYPE html>\n<html>\n</html>\n\n"
                    end

                    it 'ignores it' do
                        expect(subject.to_html).to eq expected
                    end

                    context 'with parent' do
                        %w(option textarea title script).each do |e|
                            context e do
                                let(:html) do
                                    <<-EOHTML
                                <#{e}>
                                    Stuff
                                </#{e}>
                                    EOHTML
                                end

                                let(:expected) do
                                    "<!DOCTYPE html>\n<#{e}>\n    Stuff\n</#{e}>\n\n"
                                end

                                it 'includes it' do
                                    expect(subject.to_html).to eq expected
                                end
                            end
                        end
                    end
                end

                context 'Element' do
                    let(:html) do
                        <<-EOHTML
                        <html>
                        </html>
                        EOHTML
                    end

                    let(:expected) do
                        "<!DOCTYPE html>\n<html>\n</html>\n\n"
                    end

                    it 'ignores it' do
                        expect(subject.to_html).to eq expected
                    end

                    context 'input' do
                        let(:html) do
                            <<-EOHTML
                                <input>
                            EOHTML
                        end

                        let(:expected) do
                            "<!DOCTYPE html>\n<input />\n\n"
                        end

                        it 'includes it' do
                            expect(subject.to_html).to eq expected
                        end
                    end

                    %w(form textarea option title script).each do |e|
                        context e do
                            let(:html) do
                                <<-EOHTML
                                <#{e}></#{e}>
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n<#{e}>\n</#{e}>\n\n"
                            end

                            it 'includes it' do
                                expect(subject.to_html).to eq expected
                            end
                        end
                    end

                    context 'frame' do
                        context 'without src' do
                            let(:html) do
                                <<-EOHTML
                                <frame>
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n\n"
                            end

                            it 'ignores it' do
                                expect(subject.to_html).to eq expected
                            end
                        end

                        context 'with empty src' do
                            let(:html) do
                                <<-EOHTML
                                <frame src="">
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n\n"
                            end

                            it 'ignores it' do
                                expect(subject.to_html).to eq expected
                            end
                        end

                        context 'with src' do
                            let(:html) do
                                <<-EOHTML
                                <frame src="stuff">
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n<frame src=\"stuff\" />\n\n"
                            end

                            it 'includes it' do
                                expect(subject.to_html).to eq expected
                            end
                        end
                    end

                    %w(base area link).each do |e|
                        context e do
                            context 'without href' do
                                let(:html) do
                                    <<-EOHTML
                                        <#{e}>
                                    EOHTML
                                end

                                let(:expected) do
                                    "<!DOCTYPE html>\n\n"
                                end

                                it 'ignores it' do
                                    expect(subject.to_html).to eq expected
                                end
                            end

                            context 'with empty href' do
                                let(:html) do
                                    <<-EOHTML
                                        <#{e} href="">
                                    EOHTML
                                end

                                let(:expected) do
                                    "<!DOCTYPE html>\n\n"
                                end

                                it 'ignores it' do
                                    expect(subject.to_html).to eq expected
                                end
                            end

                            context 'with href' do
                                let(:html) do
                                    <<-EOHTML
                                        <#{e} href="stuff">
                                    EOHTML
                                end

                                let(:expected) do
                                    "<!DOCTYPE html>\n<#{e} href=\"stuff\" />\n\n"
                                end

                                it 'includes it' do
                                    expect(subject.to_html).to eq expected
                                end
                            end
                        end
                    end

                    context 'a' do
                        context 'without href' do
                            let(:html) do
                                <<-EOHTML
                                    <a></a>
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n\n"
                            end

                            it 'ignores it' do
                                expect(subject.to_html).to eq expected
                            end
                        end

                        context 'with empty href' do
                            let(:html) do
                                <<-EOHTML
                                    <a href=""></a>
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n\n"
                            end

                            it 'ignores it' do
                                expect(subject.to_html).to eq expected
                            end
                        end

                        context 'with href' do
                            let(:html) do
                                <<-EOHTML
                                    <a href="stuff"></a>
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n<a href=\"stuff\">\n</a>\n\n"
                            end

                            it 'includes it' do
                                expect(subject.to_html).to eq expected
                            end
                        end
                    end
                end

                context 'meta' do
                    context 'without http-equiv' do
                        let(:html) do
                            <<-EOHTML
                            <meta>
                            EOHTML
                        end

                        let(:expected) do
                            "<!DOCTYPE html>\n\n"
                        end

                        it 'ignores it' do
                            expect(subject.to_html).to eq expected
                        end
                    end

                    context 'with empty http-equiv' do
                        let(:html) do
                            <<-EOHTML
                            <meta http-equiv="">
                            EOHTML
                        end

                        let(:expected) do
                            "<!DOCTYPE html>\n\n"
                        end

                        it 'ignores it' do
                            expect(subject.to_html).to eq expected
                        end
                    end

                    context 'with http-equiv' do
                        context 'set-cookie' do
                            let(:html) do
                                <<-EOHTML
                                    <meta http-equiv="set-cookie" content="s=1">
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n<meta http-equiv=\"set-cookie\" content=\"s=1\" />\n\n"
                            end

                            it 'includes it' do
                                expect(subject.to_html).to eq expected
                            end
                        end

                        context 'refresh' do
                            let(:html) do
                                <<-EOHTML
                                    <meta http-equiv="refresh" content="s=1">
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n<meta http-equiv=\"refresh\" content=\"s=1\" />\n\n"
                            end

                            it 'includes it' do
                                expect(subject.to_html).to eq expected
                            end
                        end

                        context 'other' do
                            let(:html) do
                                <<-EOHTML
                                    <meta http-equiv="stuff" content="s=1">
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n\n"
                            end

                            it 'ignores it' do
                                expect(subject.to_html).to eq expected
                            end
                        end
                    end
                end

                %w(select button).each do |e|
                    context e do
                        context 'without name' do
                            let(:html) do
                                <<-EOHTML
                                    <#{e}></#{e}>
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n\n"
                            end

                            it 'ignores it' do
                                expect(subject.to_html).to eq expected
                            end
                        end

                        context 'without id' do
                            let(:html) do
                                <<-EOHTML
                                    <#{e}></#{e}>
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n\n"
                            end

                            it 'ignores it' do
                                expect(subject.to_html).to eq expected
                            end
                        end

                        context 'with empty name' do
                            let(:html) do
                                <<-EOHTML
                                    <#{e} name=""></#{e}>
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n\n"
                            end

                            it 'ignores it' do
                                expect(subject.to_html).to eq expected
                            end
                        end

                        context 'with empty id' do
                            let(:html) do
                                <<-EOHTML
                                    <#{e} id=""></#{e}>
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n\n"
                            end

                            it 'ignores it' do
                                expect(subject.to_html).to eq expected
                            end
                        end

                        context 'with name' do
                            let(:html) do
                                <<-EOHTML
                                    <#{e} name="stuff"></#{e}>
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n<#{e} name=\"stuff\">\n</#{e}>\n\n"
                            end

                            it 'includes it' do
                                expect(subject.to_html).to eq expected
                            end
                        end

                        context 'with id' do
                            let(:html) do
                                <<-EOHTML
                                    <#{e} id="stuff"></#{e}>
                                EOHTML
                            end

                            let(:expected) do
                                "<!DOCTYPE html>\n<#{e} id=\"stuff\">\n</#{e}>\n\n"
                            end

                            it 'includes it' do
                                expect(subject.to_html).to eq expected
                            end
                        end
                    end
                end

            end
        end
    end

    describe '#name' do
        it 'returns self' do
            expect(subject.name).to be :document
        end
    end

    describe '#to_html' do
        it 'generates HTML code from nodes' do
            html = <<-EOHTML
<!DOCTYPE html>
<html>
    <div id="my-id">
        <!-- My comment -->
        <p class="my-class">
            <a href="/stuff">
                Stuff
            </a>
        </p>
        My text
    </div>
</html>
            EOHTML

            expect(subject.to_html.strip).to eq html.strip
        end
    end
end
