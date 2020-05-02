Factory.define :cookie, class: SCNR::Engine::Element::Cookie,
               options: {
                   url:    'http://test.com',
                   inputs: { stuff: 1 },
               }

Factory.alias :cookie_dom, :cookie
