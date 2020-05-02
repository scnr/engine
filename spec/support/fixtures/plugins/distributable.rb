=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Plugins::Distributable < SCNR::Engine::Plugin::Base

    def run
        wait_while_framework_running
        register_results( 'stuff' => 1 )
    end

    def self.info
        {
            name:        'Distributable',
            description: %q{},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            issue:       {
                tags: [ 'distributable_string', :distributable_sym ]
            }
        }
    end

end
