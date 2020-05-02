Factory.define :genericdom do
    SCNR::Engine::Element::GenericDOM.new(
        url:        Factory[:dom].url,
        transition: Factory[:input_transition]
    )
end
