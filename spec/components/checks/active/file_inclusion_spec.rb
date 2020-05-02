require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.cost
        26
    end

    def self.platforms
        [:unix, :windows, :php, :perl, :java]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::NestedCookie,
          Element::Header, Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element_per_platform
        {
            unix:    {
                Element::Form         => 16,
                Element::Link         => 16,
                Element::Cookie       => 8,
                Element::Header       => 4,
                Element::LinkTemplate => 16,
                Element::JSON         => 8,
                Element::XML          => 8,
                Element::NestedCookie => 16
            },
            windows: {
                Element::Form         => 72,
                Element::Link         => 72,
                Element::Cookie       => 36,
                Element::Header       => 18,
                Element::LinkTemplate => 72,
                Element::JSON         => 36,
                Element::XML          => 36,
                Element::NestedCookie => 72
            },
            java:    {
                Element::Form         => 8,
                Element::Link         => 8,
                Element::Cookie       => 4,
                Element::Header       => 2,
                Element::LinkTemplate => 6,
                Element::JSON         => 4,
                Element::XML          => 4,
                Element::NestedCookie => 8
            },
            php:  {
                Element::Form         => 96,
                Element::Link         => 96,
                Element::Cookie       => 44,
                Element::Header       => 22,
                Element::LinkTemplate => 94,
                Element::JSON         => 44,
                Element::XML          => 44,
                Element::NestedCookie => 88
            },
            perl:  {
                Element::Form         => 96,
                Element::Link         => 96,
                Element::Cookie       => 48,
                Element::Header       => 24,
                Element::LinkTemplate => 94,
                Element::JSON         => 48,
                Element::XML          => 48,
                Element::NestedCookie => 96
            }
        }
    end

    easy_test
end
