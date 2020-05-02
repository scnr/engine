require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.cost
        14
    end

    def self.platforms
        [:unix, :windows, :java]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::NestedCookie,
          Element::Header, Element::JSON, Element::XML ]
    end

    def issue_count_per_element_per_platform
        {
            unix:    {
                Element::Form         => 16,
                Element::Link         => 16,
                Element::Cookie       => 8,
                Element::Header       => 4,
                Element::JSON         => 12,
                Element::XML          => 8,
                Element::NestedCookie => 16
            },
            windows: {
                Element::Form         => 24,
                Element::Link         => 24,
                Element::Cookie       => 12,
                Element::Header       => 6,
                Element::JSON         => 18,
                Element::XML          => 12,
                Element::NestedCookie => 24
            },
            java:    {
                Element::Form         => 8,
                Element::Link         => 7,
                Element::Cookie       => 4,
                Element::Header       => 2,
                Element::JSON         => 6,
                Element::XML          => 4,
                Element::NestedCookie => 7
            }
        }
    end

    easy_test
end
