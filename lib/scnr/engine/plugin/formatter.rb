=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Plugin

# Will be extended by plugin formatters which provide plugin data formatting
# for the reports.
#
# Plugin formatters will be in turn ran by {SCNR::Engine::Report::Bas#format_plugin_results}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Formatter
    include UI::Output

    attr_reader :parent
    attr_reader :report
    attr_reader :results
    attr_reader :description

    def initialize( parent, report, plugin_data )
        @parent       = parent
        @report       = report
        @results      = plugin_data[:results]
        @description  = plugin_data[:description]
    end

    # @abstract
    def run
    end

end

end
end
