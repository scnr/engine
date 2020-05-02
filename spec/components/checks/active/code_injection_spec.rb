require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.cost
        4
    end

    def self.platforms
        [:php, :perl, :python, :asp]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::NestedCookie,
          Element::Header, Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        {
            Element::Form         => 6,
            Element::Link         => 3,
            Element::Cookie       => 3,
            Element::Header       => 4,
            Element::LinkTemplate => 6,
            Element::JSON         => 3,
            Element::XML          => 6,
            Element::NestedCookie => 6
        }
    end

    easy_test
end
