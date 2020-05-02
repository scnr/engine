require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    before( :each ){ framework.sitemap.clear }

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def self.cost
        999999
    end

    def self.sink
        {
            areas: [:body]
        }
    end

end
