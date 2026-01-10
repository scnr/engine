require 'spec_helper'

if !SCNR::Engine.windows?
    require SCNR::Engine::Options.paths.support + 'signature_ext'

    describe SCNR::Engine::Support::SignatureExt do
        it_behaves_like 'signature'
        
        # Additional tests to ensure String coercion works properly
        # after migration from Rutie to Magnus
        describe 'String type coercion' do
            let(:test_string) { 'test data 123 456' }
            
            it 'accepts String input in #refine method' do
                sig = described_class.new('apple banana cherry')
                expect { sig.refine('apple banana') }.not_to raise_error
            end
            
            it 'accepts String input in #refine! method' do
                sig = described_class.new('apple banana cherry')
                expect { sig.refine!('apple banana') }.not_to raise_error
            end
            
            it 'maintains functionality after multiple String refinements' do
                sig = described_class.new(test_string)
                10.times { sig = sig.refine(test_string) }
                
                expect(sig).to be_a(SCNR::Engine::Rust::Support::Signature)
                expect(sig.size).to be > 0
            end
            
            it 'preserves extended methods after dup' do
                sig = described_class.new(test_string)
                duped = sig.dup
                
                # Should have the normalize method (private)
                expect(duped.respond_to?(:normalize, true)).to be true
            end
        end
    end
end
