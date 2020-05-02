require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.cost
        3
    end

    def self.sink
        {
            areas: [:active],
            seed:  %w('" ]]]]]]]]] <!--).join
        }
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::NestedCookie,
          Element::Header, Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        {
            Element::Form         => 150,
            Element::Link         => 350,
            Element::Cookie       => 300,
            Element::Header       => 75,
            Element::LinkTemplate => 150,
            Element::JSON         => 75,
            Element::XML          => 150,
            Element::NestedCookie => 225
        }
    end

    easy_test
end
