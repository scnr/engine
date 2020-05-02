require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.cost
        3
    end

    def self.sink
        {
            areas: [:active]
        }
    end

    def self.elements
        [ Element::Form::DOM, Element::Link::DOM, Element::Cookie::DOM,
          Element::UIForm::DOM ]
    end

    def issue_count_per_element
        {
            Element::Form::DOM   => 1,
            Element::Link::DOM   => 3,
            Element::Cookie::DOM => 3,
            Element::UIForm::DOM => 1
        }
    end

    easy_test
end
