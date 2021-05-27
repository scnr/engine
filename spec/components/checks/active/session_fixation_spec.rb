require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    before :all do
        SCNR::Engine::Options.session.check_url     = url
        SCNR::Engine::Options.session.check_pattern = /dear user/
    end

    def self.cost
        4
    end

    def self.sink
        {
            areas: [:header_value]
        }
    end

    def self.elements
        [ Element::Form, Element::Link, Element::LinkTemplate ]
    end

    def issue_count
        8
    end

    easy_test
end
