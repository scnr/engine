=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Beeps when the scan finishes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.2
class SCNR::Engine::Plugins::BeepNotify < SCNR::Engine::Plugin::Base

    def run
        wait_while_framework_running
        options[:repeat].times do
            sleep options[:interval]
            print_info 'Beep!'
            print 7.chr
        end
    end

    def self.info
        {
            name: 'Beep notify',
            description: %q{It beeps when the scan finishes.},
            author: 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version: '0.1.2',
            options: [
                Options::Int.new( 'repeat',
                    description: 'How many times to beep.',
                    default:     4
                ),
                Options::Float.new( 'interval',
                    description: 'How long to wait between beeps.',
                    default:     0.4
                )
            ]
        }
    end

end
