require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.cost
        9
    end

    def self.sink
        {
            areas: [:body]
        }
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::NestedCookie,
          Element::Header, Element::LinkTemplate ]
    end

    def issue_count_per_element
        {
            Element::Form         => 8,
            Element::Link         => 4,
            Element::Cookie       => 4,
            Element::Header       => 3,
            Element::LinkTemplate => 1,
            Element::NestedCookie => 4
        }
    end

    easy_test
end
