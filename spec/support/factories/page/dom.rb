Factory.define :dom_data do
    {
        transitions:          [
            Factory[:page_load_with_cookies_transition].complete,
            Factory[:input_transition].complete,
            Factory[:form_input_transition].complete
        ],
        digest:               'stuff',
        data_flow_sinks:      [ Factory[:data_flow] ],
        execution_flow_sinks: [ Factory[:execution_flow] ]
    }
end

Factory.define :dom do
    Factory[:page].dom
end
