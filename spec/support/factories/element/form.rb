Factory.define :form, class: SCNR::Engine::Element::Form,
               options: {
                   url:    'http://test.com',
                   inputs: { stuff: 1 }
               }

Factory.define :form_dom, class: SCNR::Engine::Element::Form,
               options: {
                   url:    'http://test.com',
                   inputs: { stuff: 1 },
                   source: '<form><inputs name="stuff" value="1">'
               }
