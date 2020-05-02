Factory.define :json, class: SCNR::Engine::Element::JSON,
               options: {
                   url:    'http://test.com',
                   inputs: { stuff: 1 }
               }
