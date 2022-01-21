=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Loads and runs an external Ruby script under the scope of a plugin,
# used for debugging and general hackery.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.2
class SCNR::Engine::Plugins::Script < SCNR::Engine::Plugin::Base

    def run
        if defined?( SCNR::Engine::RPC::Server::Framework ) &&
            framework.is_a?( SCNR::Engine::RPC::Server::Framework )
            print_error 'Cannot be executed while running as an RPC server.'
            return
        end

        print_status "Loading #{options[:path]}"
        eval IO.read( options[:path] )
        print_status 'Done!'
    end

    def self.info
        {
            name:        'Script',
            description: %q{
Loads and runs an external Ruby script under the scope of a plugin, used for
debugging and general hackery.

_Will not work over RPC._
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            options:     [
                Options::Path.new( :path,
                    required:    true,
                    description: 'Path to the script.'
                )
            ]
        }
    end

end
