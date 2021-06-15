require 'spec_helper'

describe SCNR::Engine::Error do
    it 'inherits from StandardError' do
        expect(SCNR::Engine::Error <= StandardError).to be_truthy

        caught = false
        begin
            fail SCNR::Engine::Error
        rescue StandardError => e
            caught = true
        end
        expect(caught).to be_truthy

        caught = false
        begin
            fail SCNR::Engine::Error
        rescue
            caught = true
        end
        expect(caught).to be_truthy
    end

    it 'notifies' do
        exception = nil
        described_class.on_new do |e|
            exception = e
        end

        ex = described_class.new
        expect(exception).to eq ex
    end
end
