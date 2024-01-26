=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class SCNR::Engine::Plugins::PageDump < SCNR::Engine::Plugin::Base

    def run
        cnt  = 0
        seen = Support::Filter::HashSet.new

        framework.before_page_audit do |page|
            data = {
                url:         page.dom.url,
                response:    page.response.to_s,
                request:     page.request.to_s,
                source:      page.body,
                transitions: page.dom.transitions.map(&:to_h)
            }

            next if seen.include? data
            seen << data

            cnt += 1
            IO.write( "#{@options[:directory]}/#{cnt}.yaml", data.to_yaml )
        end

        wait_while_framework_running
    end

    def self.info
        {
            name:        'Page dump',
            description: %q{
Dumps the following page data to disk as YAML:

* URL
* Raw HTTP response
* Raw HTTP request
* Page source -- can differ due to JS.
* DOM transitions

The plugin will create one file for each unique page.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            options:     [
                Options::Path.new( :directory,
                    description: 'Directory where which to save page data.'
                )
            ]
        }
    end

end
