Factory.define :header, class: SCNR::Engine::Element::Header,
               options: {
                   url:    'http://test.com',
                   inputs: { stuff: 1 },
               }
