Factory.define :page do
    SCNR::Engine::Page.new(
        response: Factory[:response],
        dom:      Factory[:dom_data]
    # Load all elements to populate metadata and the like but clear the cache.
    ).tap(&:elements).tap(&:clear_cache)
end

Factory.define :empty_page do
    SCNR::Engine::Page.from_data(
        response: {
            code: 0,
            url:  Factory[:response].url
        }
    )
end
