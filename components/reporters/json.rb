=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'json'

# Converts the Report to a Hash which it then dumps in JSON format into a file.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.3
class SCNR::Engine::Reporters::JSON < SCNR::Engine::Reporter::Base

    def run
        print_line
        print_status "Dumping audit results in #{outfile}."

        File.open( outfile, 'w' ) do |f|
            begin
                f.write ::JSON::pretty_generate( report.to_h )
            rescue Encoding::UndefinedConversionError
                f.write ::JSON::pretty_generate( report.to_h.recode )
            end
        end

        print_status 'Done!'
    end

    def self.info
        {
            name:         'JSON',
            description:  %q{Exports the audit results as a JSON (.json) file.},
            content_type: 'application/json',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:      '0.1.3',
            options:      [ Options.outfile( '.json' ) ]
        }
    end

end
