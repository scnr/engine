=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'ap'

#
# Awesome prints an {Report#to_hash} hash.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class SCNR::Engine::Reporters::AP < SCNR::Engine::Reporter::Base

    def run
        print_line
        print_status 'Awesome printing Report as a Hash...'

        ap report.to_hash

        print_status 'Done!'
    end

    def self.info
        {
            name:        'AP',
            description: %q{Awesome prints a scan report hash.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1'
        }
    end

end
