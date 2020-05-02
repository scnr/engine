shared_examples_for 'sinks' do |options = {}|

    before(:each) { enable_browser_cluster }

    let( :opts ) do
        {
            single_input: false,
            base_url:     nil
        }.merge( options )
    end

    let(:url) do
        "#{super()}#{opts[:base_url]}"
    end

    let(:inputs) do
        return opts[:inputs] if opts[:inputs]

        if opts[:single_input]
            { 'active' => 'value1' }
        else
            {
                'active' => 'value1',
                'blind'  => 'value2'
            }
        end
    end

    let(:active_input) do
        if opts[:single_input]
            'active'
        else
            inputs.keys.find { |i| i.include? 'active' }
        end
    end

    let(:blind_input) do
        if opts[:single_input]
            'blind'
        else
            inputs.keys.find { |i| i.include? 'blind' }
        end
    end

    let(:with_sinks) do
        if defined? super
            super()
        else
            ws = subject.dup
            ws.inputs = inputs
            ws
        end
    end

    before :each do
        SCNR::Engine::State.sink_tracer.clear
        described_class::Sinks.reset
        described_class::Sinks.enable_all
        described_class::Sinks.add_to_max_cost 9999

        begin
            SCNR::Engine::Options.audit.elements described_class.type
        rescue SCNR::Engine::OptionGroups::Audit::Error => e
        end
    end

    after :each do
        reset_options
    end

    describe '#trace' do
        context 'when the value' do
            context 'is included in the body' do
                let(:in_body) do
                    if defined? with_sinks_in_body
                        with_sinks_in_body
                    else
                        with_sinks.action = "#{url}/sinks/body"
                        with_sinks
                    end
                end

                let(:per_input) do
                    if opts[:single_input]
                        {
                            active_input => [:traced, :active, :body].sort
                        }
                    else
                        {
                            active_input => [:traced, :active, :body].sort,
                            blind_input  => [:traced, :blind].sort
                        }
                    end
                end

                it 'assigns the proper sinks' do
                    in_body.sinks.trace
                    run

                    expect(in_body.sinks.per_input).to eq per_input
                end
            end

            context 'is included in a header name',
                    if: !described_class.ancestors.include?( SCNR::Engine::Element::DOM ) do

                let(:in_header_name) do
                    header_name = with_sinks.dup
                    header_name.action = "#{url}/sinks/header/name"
                    header_name.inputs = inputs
                    header_name
                end

                let(:per_input) do
                    if opts[:single_input]
                        {
                            active_input => [:traced, :blind, :header_name].sort
                        }
                    else
                        {
                            active_input => [:traced, :blind, :header_name].sort,
                            blind_input  => [:traced, :blind].sort
                        }
                    end
                end

                it 'assigns the proper sinks' do
                    in_header_name.sinks.trace
                    run

                    expect(in_header_name.sinks.per_input).to eq per_input
                end
            end

            context 'is included in a header value',
                    if: !described_class.ancestors.include?( SCNR::Engine::Element::DOM ) do

                let(:in_header_value) do
                    header_value = with_sinks.dup
                    header_value.action = "#{url}/sinks/header/value"
                    header_value.inputs = inputs
                    header_value
                end

                let(:per_input) do
                    if opts[:single_input]
                        {
                            active_input => [:traced, :blind, :header_value].sort
                        }
                    else
                        {
                            active_input => [:traced, :blind, :header_value].sort,
                            blind_input  => [:traced, :blind].sort
                        }
                    end
                end

                it 'assigns the proper sinks' do
                    in_header_value.sinks.trace
                    run

                    expect(in_header_value.sinks.per_input).to eq per_input
                end
            end

            context 'has no effect on the page' do
                let(:blind) do
                    if defined? with_sinks_blind
                        with_sinks_blind
                    else
                        e = with_sinks.dup
                        e.action = "#{url}/sinks/blind"
                        e.inputs = inputs
                        e
                    end
                end

                let(:per_input) do
                    if opts[:single_input]
                        {
                            active_input => [:traced, :blind].sort
                        }
                    else
                        {
                            active_input => [:traced, :blind].sort,
                            blind_input  => [:traced, :blind].sort
                        }
                    end
                end

                it 'assigns the proper sinks' do
                    blind.sinks.trace
                    run

                    expect(blind.sinks.per_input).to eq per_input
                end
            end

            context 'affects on the page' do
                let(:active) do
                    if defined? with_sinks_active
                        with_sinks_active
                    else
                        e = with_sinks.dup
                        e.action = "#{url}/sinks/active"
                        e.inputs = inputs
                        e
                    end
                end

                let(:per_input) do
                    if opts[:single_input]
                        {
                            active_input => [:traced, :active].sort
                        }
                    else
                        {
                            active_input => [:traced, :active].sort,
                            blind_input  => [:traced, :blind].sort
                        }
                    end
                end

                it 'assigns the proper sinks' do
                    active.sinks.trace
                    run

                    expect(active.sinks.per_input).to eq per_input
                end
            end
        end

        it 'returns true'

        it 'uses the tracer returned by .select_tracer'

        context 'when .acceptable_cost?' do
            context 'returns true for the tracer' do
                it 'runs the trace'
            end

            context 'returns false for the tracer' do
                it 'does not run the trace'
                it 'marks all mutations as #override!'
            end
        end

        context 'when sinks have already been traced' do
            it "raises #{described_class::Sinks::Error::DuplicateTrace}"
        end

        context 'when no sinks have been enabled' do
            it 'does not trace'
            it 'returns nil'
        end
    end

    describe '.max_cost' do
        it 'returns the maximum allowed cost of the trace'

        context 'by default' do
            it 'is 0'
        end
    end

    describe '.add_to_max_cost' do
        it 'adds the given number to the .max_cost'
    end

    describe '.acceptable_cost?' do
        context 'when the given trace cost is greater than the .max_cost' do
            it 'returns false'
        end

        context 'when the given trace cost is less than the .max_cost' do
            it 'returns true'
        end
    end

    describe '.enabled' do
        it 'returns enabled sinks'
    end

    describe '.enabled?' do
        context 'when the sink has been enabled' do
            it 'returns true'
        end

        context 'when any of the sinks have been enabled' do
            it 'returns true'
        end

        context 'when the sink has not been enabled' do
            it 'returns false'
        end

        context 'when none of the sinks have been enabled' do
            it 'returns false'
        end
    end

    describe '.enable' do
        it 'enables the given sink'

        context 'when the sink is not supported' do
            it "raises #{described_class::Sinks::Error::InvalidSink}"
        end
    end

    describe '.enable_all' do
        it 'enables all supported sinks'
    end

    describe '.tracers' do
        it 'returns loaded tracers'
    end

    describe '.register_tracer' do
        it 'registers a tracer'

        context 'when no sinks are given' do
            it 'uses the tracer name'
        end
    end

    describe '.select_tracer' do
        it 'picks the most cost-effective tracer for the enabled sinks'
    end

    describe '.select_tracer_for' do
        it 'picks the most cost-effective tracer for the given sinks'
    end

    describe '.supported?' do
        context'when the given sink is supported by a tracer' do
            it 'returns true'
        end

        context'when the given sink is not supported by any tracer' do
            it 'returns false'
        end
    end

    describe '.supported' do
        it 'returns sinks supported by the loaded tracers'
    end

    describe '.add_to_extra_seed' do
        it 'adds the given string to the extra analysis seed'

        context 'when the given seed already exists in the seed' do
            it 'does not add it'
        end
    end

    describe '.extra_seed' do
        it 'returns an empty string'

        context 'when extra strings have been provided' do
            it 'concatenates them'
        end
    end

    described_class::Sinks.supported.each do |sink|
        describe "#{sink}?" do
            context 'when the mutation has that sink' do
                it 'returns true' do
                    with_sinks.affected_input_name = active_input
                    with_sinks.sinks.send("#{sink}!")

                    expect(with_sinks.sinks.send("#{sink}?")).to be_truthy
                end
            end

            context 'when the mutation does not have that sink' do
                it 'returns true' do
                    with_sinks.affected_input_name = active_input

                    expect(with_sinks.sinks.send("#{sink}?")).to be_falsey
                end
            end

            context 'when called on the parent element' do
                context 'when the mutation has that sink' do
                    it 'returns true' do
                        m = with_sinks.dup
                        m.affected_input_name = active_input
                        m.sinks.send("#{sink}!")

                        expect(with_sinks.sinks.send("#{sink}?")).to be_truthy
                    end
                end

                context 'when the mutation does not have that sink' do
                    it 'returns true' do
                        m = with_sinks.dup
                        m.affected_input_name = active_input

                        expect(with_sinks.sinks.send("#{sink}?")).to be_falsey
                    end
                end
            end
        end

        describe "#{sink}!" do
            context 'when called on a mutation' do
                it 'sets the sink' do
                    m = with_sinks.dup
                    m.affected_input_name = active_input

                    expect(with_sinks.sinks.send("#{sink}?")).to be_falsey

                    m.sinks.send("#{sink}!")

                    expect(with_sinks.sinks.send("#{sink}?")).to be_truthy
                end
            end

            context 'when called on a parent' do
                it 'raises error' do
                    expect do
                        with_sinks.sinks.send("#{sink}!")
                    end.to raise_error
                end
            end
        end

        describe "#{sink}" do
            it 'returns inputs with that sink' do
                m = with_sinks.dup
                m.affected_input_name = active_input

                m.sinks.send("#{sink}!")

                expect(with_sinks.sinks.send("#{sink}")).to eq Set.new([m.affected_input_name])
                expect(m.sinks.send("#{sink}")).to eq Set.new([m.affected_input_name])
            end
        end
    end

end
