require 'scnr/engine'
require 'dsel'

module SCNR
module Engine

DSeL::DSL::Nodes::APIBuilder.build :API, namespace: self do
    import_relative_many 'api/*'

end

end
end
