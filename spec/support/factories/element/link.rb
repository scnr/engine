Factory.define :link, class: SCNR::Engine::Element::Link,
               options: {
                   url:    'http://test.com',
                   inputs: { stuff: 1 }
               }

Factory.define :link_dom, class: SCNR::Engine::Element::Link,
               options: {
                   url:  'http://test.com',
                   source: '<a href="#/?link-dom-input=1">a</a>'
               }
