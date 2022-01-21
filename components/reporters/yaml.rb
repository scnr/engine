=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Converts the Report to a Hash which it then dumps in YAML format into a file.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.2
class SCNR::Engine::Reporters::YAML < SCNR::Engine::Reporter::Base

    def run
        print_line
        print_status "Dumping audit results in #{outfile}."

        File.open( options[:outfile], 'w' ) do |f|
            f.write( report.to_hash.to_yaml )
        end

        print_status 'Done!'
    end

    def self.info
        {
            name:         'YAML',
            description:  %q{Exports the audit results as a YAML (.yaml) file.},
            content_type: 'application/x-yaml',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:      '0.2',
            options:      [ Options.outfile( '.yaml' ) ]
        }
    end

end
