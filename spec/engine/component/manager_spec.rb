require 'spec_helper'

describe SCNR::Engine::Component::Manager do

    subject { SCNR::Engine::Component::Manager.new( lib, namespace ) }
    let(:namespace) { SCNR::Engine::Plugins }
    let(:lib) { SCNR::Engine::Options.paths.plugins }
    let(:available) { %w(wait bad distributable loop default with_options suspendable).sort }

    describe '#lib' do
        it 'returns the component library' do
            expect(subject.lib).to eq(lib)
        end
    end

    describe '#namespace' do
        it 'returns the namespace under which all components are defined' do
            expect(subject.namespace).to eq(namespace)
        end
    end

    describe '#available' do
        it 'returns all available components' do
            expect(subject.available.sort).to eq(available)
        end
    end

    describe '#load_all' do
        it 'loads all components' do
            subject.load_all
            expect(subject.loaded.sort).to eq(subject.available.sort)
        end
    end

    describe '#on_load' do
        it 'gets called when a component is loaded'
    end

    describe '#load' do
        context 'when passed a' do

            context 'String' do
                it 'loads the component by name' do
                    subject.load( 'wait' )
                    expect(subject.loaded).to eq(%w(wait))
                end
            end

            context 'Symbol' do
                it 'loads the component by name' do
                    subject.load( :wait )
                    expect(subject.loaded).to eq(%w(wait))
                end
            end

            context 'Array' do
                it 'loads the components by name' do
                    subject.load( %w(bad distributable) )
                    expect(subject.loaded.sort).to eq(%w(bad distributable).sort)
                end
            end

            context 'vararg' do
                context 'String' do
                    it 'loads components by name' do
                        subject.load( 'wait', 'bad' )
                        expect(subject.loaded.sort).to eq(%w(bad wait).sort)
                    end
                end

                context 'Symbol' do
                    it 'loads components by name' do
                        subject.load :wait, :distributable
                        expect(subject.loaded.sort).to eq(%w(wait distributable).sort)
                    end
                end

                context 'Array' do
                    it 'loads components by name' do
                        subject.load( :wait, %w(bad distributable) )
                        expect(subject.loaded.sort).to eq(%w(bad distributable wait).sort)
                    end
                end
            end

            context 'wildcard (*)' do
                context 'alone' do
                    it 'loads all components' do
                        subject.load( '*' )
                        expect(subject.loaded.sort).to eq(subject.available.sort)
                    end
                end

                context 'with a category name' do
                    it 'loads all of its components' do
                        subject.load( 'defaults/*' )
                        expect(subject.loaded.sort).to eq(%w(default))
                    end
                end

            end

            context 'exclusion filter (-)' do
                context 'alone' do
                    it 'loads nothing' do
                        subject.load( '-' )
                        expect(subject.loaded.sort).to be_empty
                    end
                end
                context 'with a name' do
                    it 'ignore that component' do
                        subject.load( %w(* -wait) )
                        loaded = subject.available
                        loaded.delete( 'wait' )
                        expect(subject.loaded.sort).to eq(loaded.sort)
                    end
                end
                context 'with a partial name and a wildcard' do
                    it 'ignore matching component names' do
                        subject.load( %w(* -wai* -dist*) )
                        loaded = subject.available
                        loaded.delete( 'wait' )
                        loaded.delete( 'distributable' )
                        expect(subject.loaded.sort).to eq(loaded.sort)
                    end
                end
            end
        end

        context 'when a component is not found' do
            it 'raises SCNR::Engine::Component::Error::NotFound' do
                trigger = proc { subject.load :houa }

                expect { trigger.call }.to raise_error SCNR::Engine::Error
                expect { trigger.call }.to raise_error SCNR::Engine::Component::Error
                expect { trigger.call }.to raise_error SCNR::Engine::Component::Error::NotFound
            end
        end
    end

    describe '#load_by_tags' do
        context 'when passed' do
            context 'nil' do
                it 'returns an empty array' do
                    expect(subject.empty?).to be_truthy
                    expect(subject.load_by_tags( nil )).to eq([])
                end
            end

            context '[]' do
                it 'returns an empty array' do
                    expect(subject.empty?).to be_truthy
                    expect(subject.load_by_tags( [] )).to eq([])
                end
            end

            context 'String' do
                it 'loads components whose tags include the given tag (as either a String or a Symbol)' do
                    expect(subject.empty?).to be_truthy

                    expect(subject.load_by_tags( 'wait_string' )).to eq(%w(wait))
                    subject.delete( 'wait' )
                    expect(subject.empty?).to be_truthy

                    expect(subject.load_by_tags( 'wait_sym' )).to eq(%w(wait))
                    subject.delete( 'wait' )
                    expect(subject.empty?).to be_truthy

                    expect(subject.load_by_tags( 'distributable_string' )).to eq(%w(distributable))
                    subject.delete( 'distributable' )
                    expect(subject.empty?).to be_truthy

                    expect(subject.load_by_tags( 'distributable_sym' )).to eq(%w(distributable))
                    subject.delete( 'distributable' )
                    expect(subject.empty?).to be_truthy

                end
            end

            context 'Symbol' do
                it 'loads components whose tags include the given tag (as either a String or a Symbol)' do
                    expect(subject.empty?).to be_truthy

                    expect(subject.load_by_tags( :wait_string )).to eq(%w(wait))
                    subject.delete( 'wait' )
                    expect(subject.empty?).to be_truthy

                    expect(subject.load_by_tags( :wait_sym )).to eq(%w(wait))
                    subject.delete( 'wait' )
                    expect(subject.empty?).to be_truthy

                    expect(subject.load_by_tags( :distributable_string )).to eq(%w(distributable))
                    subject.delete( 'distributable' )
                    expect(subject.empty?).to be_truthy

                    expect(subject.load_by_tags( :distributable_sym )).to eq(%w(distributable))
                    subject.delete( 'distributable' )
                    expect(subject.empty?).to be_truthy
                end
            end

            context 'Array' do
                it 'loads components which include any of the given tags (as either Strings or a Symbols)' do
                    expect(subject.empty?).to be_truthy

                    expected = %w(wait distributable).sort
                    expect(subject.load_by_tags( [ :wait_string, 'distributable_string' ] ).sort).to eq(expected)
                    subject.clear
                    expect(subject.empty?).to be_truthy

                    expect(subject.load_by_tags( [ 'wait_string', :distributable_string ] ).sort).to eq(expected)
                    subject.clear
                    expect(subject.empty?).to be_truthy

                    expect(subject.load_by_tags( [ 'wait_sym', :distributable_sym ] ).sort).to eq(expected)
                    subject.clear
                    expect(subject.empty?).to be_truthy
                end

            end
        end
    end

    describe '#parse' do
        context 'when passed a' do

            context 'String' do
                it 'returns an array including the component\'s name' do
                    expect(subject.parse( 'wait' )).to eq(%w(wait))
                end
            end

            context 'Symbol' do
                it 'returns an array including the component\'s name' do
                    expect(subject.parse( :wait )).to eq(%w(wait))
                end
            end

            context 'Array' do
                it 'loads the component by name' do
                    expect(subject.parse( %w(bad distributable) ).sort).to eq(
                        %w(bad distributable).sort
                    )
                end
            end

            context 'wildcard (*)' do
                context 'alone' do
                    it 'returns all components' do
                        expect(subject.parse( '*' ).sort).to eq(subject.available.sort)
                    end
                end

                context 'with a category name' do
                    it 'returns all of its components' do
                        expect(subject.parse( 'defaults/*' ).sort).to eq(%w(default))
                    end
                end
            end

            context 'exclusion filter (-)' do
                context 'alone' do
                    it 'returns nothing' do
                        expect(subject.parse( '-' ).sort).to be_empty
                    end
                end
                context 'with a name' do
                    it 'ignores that component' do
                        subject.parse( %w(* -wait) )
                        loaded = subject.available
                        loaded.delete( 'wait' )
                        expect(loaded.sort).to eq(loaded.sort)
                    end
                end
                context 'with a partial name and a wildcard' do
                    it 'ignore matching component names' do
                        parsed = subject.parse( %w(* -wai* -dist*) )
                        loaded = subject.available
                        loaded.delete( 'wait' )
                        loaded.delete( 'distributable' )
                        expect(parsed.sort).to eq(loaded.sort)
                    end
                end
            end
        end
    end

    describe '#prepare_options' do
        it 'prepares options for passing to the component' do
            c = 'with_options'

            subject.load( c )
            expect(subject.prepare_options( c, subject[c],
                { 'req_opt' => 'my value' }
            )).to eq({
                req_opt:     'my value',
                default_opt: 'value'
            })

            opts = {
                'req_opt'     => 'req_opt value',
                'opt_opt'     => 'opt_opt value',
                'default_opt' => 'value2'
            }
            expect(subject.prepare_options( c, subject[c], opts )).to eq(opts.my_symbolize_keys)
        end

        context 'with missing options' do
            it "raises #{SCNR::Engine::Component::Options::Error::Invalid}" do
                trigger = proc do
                    begin
                        c = 'with_options'
                        subject.load( c )
                        subject.prepare_options( c, subject[c], {} )
                    ensure
                        subject.clear
                    end
                end

                expect { trigger.call }.to raise_error SCNR::Engine::Component::Options::Error::Invalid
            end
        end

        context 'with invalid options' do
            it "raises #{SCNR::Engine::Component::Options::Error::Invalid}" do
                opts = {
                    'req_opt'     => 'req_opt value',
                    'opt_opt'     => 'opt_opt value',
                    'default_opt' => 'default_opt value'
                }

                trigger = proc do
                    begin
                        c = 'with_options'
                        subject.load( c )
                        subject.prepare_options( c, subject[c], opts )
                    ensure
                        subject.clear
                    end
                end

                expect { trigger.call }.to raise_error SCNR::Engine::Component::Options::Error::Invalid
            end
        end
    end

    describe '#[]' do
        context 'when passed a' do
            context 'String' do
                it 'should load and return the component' do
                    expect(subject.loaded).to be_empty
                    expect(subject['wait'].name).to eq('SCNR::Engine::Plugins::Wait')
                    expect(subject.loaded).to eq(%w(wait))
                end
            end
            context 'Symbol' do
                it 'should load and return the component' do
                    expect(subject.loaded).to be_empty
                    expect(subject[:wait].name).to eq('SCNR::Engine::Plugins::Wait')
                    expect(subject.loaded).to eq(%w(wait))
                end
            end
        end
    end

    describe '#include?' do
        context 'when passed a' do
            context 'String' do
                context 'when the component has been loaded' do
                    it 'returns true' do
                        expect(subject.loaded).to be_empty
                        expect(subject['wait'].name).to eq('SCNR::Engine::Plugins::Wait')
                        expect(subject.loaded).to eq(%w(wait))
                        expect(subject.loaded?( 'wait' )).to be_truthy
                        expect(subject.include?( 'wait' )).to be_truthy
                    end
                end
                context 'when the component has not been loaded' do
                    it 'returns false' do
                        expect(subject.loaded).to be_empty
                        expect(subject.loaded?( 'wait' )).to be_falsey
                        expect(subject.include?( 'wait' )).to be_falsey
                    end
                end
            end
            context 'Symbol' do
                context 'when the component has been loaded' do
                    it 'returns true' do
                        expect(subject.loaded).to be_empty
                        expect(subject[:wait].name).to eq('SCNR::Engine::Plugins::Wait')
                        expect(subject.loaded).to eq(%w(wait))
                        expect(subject.loaded?( :wait )).to be_truthy
                        expect(subject.include?( :wait )).to be_truthy
                    end
                end
                context 'when the component has not been loaded' do
                    it 'returns false' do
                        expect(subject.loaded).to be_empty
                        expect(subject.loaded?( :wait )).to be_falsey
                        expect(subject.include?( :wait )).to be_falsey
                    end
                end
            end
        end
    end

    describe '#delete' do
        it 'removes a component' do
            expect(subject.loaded).to be_empty

            subject.load( 'wait' )
            klass = subject['wait']

            sym = klass.name.split( ':' ).last.to_sym
            expect(subject.namespace.constants.include?( sym )).to be_truthy
            expect(subject.loaded).to be_any

            subject.delete( 'wait' )
            expect(subject.loaded).to be_empty

            sym = klass.name.split( ':' ).last.to_sym
            expect(subject.namespace.constants.include?( sym )).to be_falsey
        end
        it 'unloads a component' do
            expect(subject.loaded).to be_empty

            subject.load( 'wait' )
            klass = subject['wait']

            sym = klass.name.split( ':' ).last.to_sym
            expect(subject.namespace.constants.include?( sym )).to be_truthy
            expect(subject.loaded).to be_any

            subject.delete( 'wait' )
            expect(subject.loaded).to be_empty

            sym = klass.name.split( ':' ).last.to_sym
            expect(subject.namespace.constants.include?( sym )).to be_falsey
        end
    end

    describe '#loaded' do
        it 'returns all loaded components' do
            subject.load( '*' )
            expect(subject.loaded.sort).to eq(available)
        end
    end

    describe '#name_to_path' do
        it 'returns a component\'s path from its name' do
            path = subject.name_to_path( 'wait' )
            expect(File.exists?( path )).to be_truthy
            expect(File.basename( path )).to eq('wait.rb')
        end
    end

    describe '#path_to_name' do
        it 'returns a component\'s name from its path' do
            path = subject.name_to_path( 'wait' )
            expect(subject.path_to_name( path )).to eq('wait')
        end
    end

    describe '#paths' do
        it 'returns all component paths' do
            paths = subject.paths
            paths.each { |p| expect(File.exists?( p )).to be_truthy }
            expect(paths.size).to eq(subject.available.size)
        end
    end

    describe '#clear' do
        it 'unloads all components' do
            expect(subject.loaded).to be_empty
            subject.load( '*' )
            expect(subject.loaded.sort).to eq(subject.available.sort)

            symbols = subject.values.map do |klass|
                sym = klass.name.split( ':' ).last.to_sym
                expect(subject.namespace.constants.include?( sym )).to be_truthy
                sym
            end

            subject.clear
            symbols.each do |sym|
                expect(subject.namespace.constants.include?( sym )).to be_falsey
            end
            expect(subject.loaded).to be_empty
        end
    end
end
