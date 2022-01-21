=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::WithFormatters < SCNR::Engine::Reporter::Base

    def run
        File.open( 'with_formatters', 'w' ) { |f| f.write( format_plugin_results ) }
    end

end
