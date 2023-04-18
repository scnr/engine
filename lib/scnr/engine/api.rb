require 'scnr/engine'
require 'dsel'

module SCNR
module Engine

    @errors ||= []
    SCNR::Engine::UI::Output.on_error do |error|
        @errors << error
    end
    class <<self
        def errors
            @errors
        end
    end

DSeL::DSL::Nodes::APIBuilder.build :API, namespace: self do
    import_relative_many 'api/*'
end

end
end
