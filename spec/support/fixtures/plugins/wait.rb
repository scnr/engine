=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Plugins::Wait < SCNR::Engine::Plugin::Base

    def run
        wait_while_framework_running
        register_results( 'stuff' => true )
    end

    def self.info
        {
            name:        'Wait',
            description: %q{},
            tags:        ['wait_string', :wait_sym],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1'
        }
    end

end
