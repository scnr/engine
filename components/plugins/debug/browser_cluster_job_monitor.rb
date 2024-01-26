=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class SCNR::Engine::Plugins::BrowserPoolJobMonitor < SCNR::Engine::Plugin::Base

    def run
        while framework.running?

            s = ''
            browser_pool.workers.each.with_index do |worker, i|
                s << "[#{i+1}] #{worker.job || '-'}\n"
                s << "#{'-'  * 100}\n"

                worker.proxy.active_connections.each do |connection|
                    next if !connection

                    if connection.request
                        s << "* #{connection.request.url}\n"
                    else
                        s << "* Still reading request data.\n"
                    end
                end

                s << "\n"
            end

            IO.write( options[:logfile], s )

            sleep 1
        end
    end

    def self.info
        {
            name:        'BrowserPoolJobMonitor',
            description: %q{

Monitor with:

    watch -n1 cat /tmp/browser_pool_job_monitor.log
                         },
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            options:     [
                Options::String.new( :logfile,
                    description: 'Executable to be called prior to the scan.',
                    default: '/tmp/browser_pool_job_monitor.log'
                )
            ]
        }
    end

end
