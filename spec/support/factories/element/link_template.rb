Factory.define :link_template, class: SCNR::Engine::Element::LinkTemplate,
               options: {
                   url:      'http://test.com/input1/value1/input2/value2',
                   template: /input1\/(?<input1>\w+)\/input2\/(?<input2>\w+)/
               }

Factory.define :link_template_dom, class: SCNR::Engine::Element::LinkTemplate,
               options: {
                   url:  'http://test.com/#/input1/value1/input2/value2',
                   source: '<a href="#/input1/value1/input2/value2">a</a>'
               }
