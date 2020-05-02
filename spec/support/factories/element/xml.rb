Factory.define :xml, class: SCNR::Engine::Element::XML,
               options: {
                   url:    'http://test.com',
                   source: '<input>value</input>'
               }
