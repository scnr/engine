class SCNR::Engine::Reporters::Stdout

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::SinkTracer < SCNR::Engine::Plugin::Formatter

    def run
        pp results
    end

end

end
