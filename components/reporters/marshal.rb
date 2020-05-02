=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Converts the Report to a Hash which it then dumps in Marshal format into a file.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
class SCNR::Engine::Reporters::Marshal < SCNR::Engine::Reporter::Base

    def run
        print_line
        print_status "Dumping audit results in #{outfile}."

        File.open( outfile, 'w' ) do |f|
            f.write ::Marshal::dump( report.to_hash )
        end

        print_status 'Done!'
    end

    def self.info
        {
            name:         'Marshal',
            description:  %q{Exports the audit results as a Marshal (.marshal) file.},
            content_type: 'application/x-marshal',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:      '0.1.1',
            options:      [Options.outfile('.marshal')]
        }
    end

end
