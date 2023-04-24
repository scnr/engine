require 'spec_helper'
require 'tempfile'

describe SCNR::Engine::Support::Crypto::RSA_AES_CBC do

    SEED = 'seed data'

    let(:public_key) do
        private_key.public_key
    end
    let(:private_key) do
        private_key.to_pem
    end
    let(:private_key) { OpenSSL::PKey::RSA.generate( 1024 ) }
    subject { described_class.new( public_key, private_key ) }

    it 'generates matching encrypted and decrypted data' do
        expect(subject.decrypt( subject.encrypt( SEED ) )).to eq(SEED)
    end

end
