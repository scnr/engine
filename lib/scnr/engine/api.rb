require 'dsel'

module SCNR
module Engine

DSeL::DSL::Nodes::APIBuilder.build :API, namespace: self do
    import_relative_many 'api/*'

    define :run!

    def_run! do |&block|
        SCNR::Engine::Framework.safe do |framework|
            framework.checks.load SCNR::Engine::Options.checks

            framework.plugins.load_defaults
            framework.plugins.load SCNR::Engine::Options.plugins.keys

            framework.run do
                block.call(
                  Hash[framework.sitemap.sort_by{ |u,_| u }],
                  SCNR::Engine::Data.issues.sort,
                  framework.statistics
                )
            end
        end
    end

end

end
end
