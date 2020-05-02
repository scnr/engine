require 'spec_helper'

describe SCNR::Engine::Parser::Nodes::Base do
    subject { SCNR::Engine::Parser.parse( html ) }
    let(:html) do
        <<-EOHTML
        <html>
            <div id="my-id">
                <!-- My comment -->
                <p class="my-class">
                    <a href="/stuff">
                        <span data-id='deepest'>Deepest</span>
                    </a>
                </p>

                <span id='second-span'>Second span</span>

                My text
            </div>
        </html>
        EOHTML
    end

    def summarize( n )
        if n.is_a? SCNR::Engine::Parser::Nodes::Element
            [n.name, n.attributes]
        else
            [n.class.to_s.split( '::' ).last.to_sym, n.text]
        end
    end

    it { respond_to :free }

    describe '#traverse' do
        it 'passes each descendant node to the block' do
            nodes = []

            subject.traverse do |n|
                nodes << summarize( n )
            end

            expect(nodes).to eq([
                [:html, {}],
                [:div, {"id"=>"my-id"}],
                [:Comment, "My comment"],
                [:p, {"class"=>"my-class"}],
                [:a, {"href"=>"/stuff"}],
                [:span, {"data-id"=>"deepest"}],
                [:Text, "Deepest"],
                [:span, {"id"=>"second-span"}],
                [:Text, "Second span"],
                [:Text, "My text"]
            ])
        end
    end

    describe '#traverse_comments' do
        let(:html) do
            <<-EOHTML
        <html>
            <div id="my-id">
                <!-- My comment -->
                <p class="my-class">
                    <a href="/stuff">
                        <!-- My other comment -->
                        <span data-id='deepest'>Deepest</span>
                    </a>
                </p>

                <span id='second-span'>Second span</span>

                My text
            </div>

            <!-- My last comment -->
        </html>
            EOHTML
        end

        it 'passes each descendant node to the block' do
            nodes = []

            subject.traverse_comments do |n|
                nodes << summarize( n )
            end

            expect(nodes).to eq([
                [:Comment, "My comment"],
                [:Comment, "My other comment"],
                [:Comment, "My last comment"],
            ])
        end
    end

    describe '#nodes_by_name' do
        it 'returns all descendant nodes that have the given tag name' do
            nodes = []
            subject.nodes_by_name( :span ) { |n| nodes << summarize( n ) }

            expect(nodes).to eq([
                [:span, {"data-id"=>"deepest"}],
                [:span, {"id"=>"second-span"}]
            ])

            nodes = []
            subject.nodes_by_name( :a ) do |n|
                n.nodes_by_name( :span ) { |n2| nodes << summarize( n2 ) }
            end

            expect(nodes).to eq([
                [:span, {"data-id"=>"deepest"}]
            ])
        end
    end

    describe '#nodes_by_names' do
        it 'returns all descendant nodes that have the given tag names' do
            nodes = []
            subject.nodes_by_names( :span, :a ) { |n| nodes << summarize( n ) }

            expect(nodes).to eq([
                [:span, {"data-id"=>"deepest"}],
                [:span, {"id"=>"second-span"}],
                [:a, {"href"=>"/stuff"}]
            ])
        end
    end

    describe '#nodes_by_attribute_name_and_value' do
        let(:html) do
            <<-EOHTML
        <html>
            <span id='my-span'>Span</span>

            <span iD='Other-Span'>Other span</span>
        </html>
            EOHTML
        end

        it 'returns all descendant nodes that have the given attribute name' do
            nodes = []
            subject.nodes_by_attribute_name_and_value( 'id', 'my-span' ) { |n| nodes << summarize( n ) }
            expect(nodes).to eq([
                [:span, {"id"=>"my-span"}],
            ])
        end

        it 'is case insensitive' do
            nodes = []
            subject.nodes_by_attribute_name_and_value( 'id', 'other-span' ) { |n| nodes << summarize( n ) }
            expect(nodes).to eq([
                [:span, {"id"=>"Other-Span"}],
            ])
        end
    end

end
