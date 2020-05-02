require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.cost
        28
    end

    def self.sink
        { areas: [:active] }
    end

    def self.platforms
        [:nosql]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::NestedCookie ]
    end

    def issue_count
        6
    end

    easy_test
end
