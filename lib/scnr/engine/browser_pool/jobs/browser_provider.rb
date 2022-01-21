=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class BrowserPool
module Jobs

# Works together with {BrowserPool#with_browser} to provide the callback
# for this job with the {Browser} assigned to this job.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class BrowserProvider < Job

    def initialize( *args )
        super()

        @args = args
    end

    def run
        browser.master.callback_for( self ).call *[browser, @args].flatten.compact
    end

    def to_s
        "#<#{self.class}:#{object_id} " <<
            "callback=#{browser.master.callback_for( self ) if browser && browser.master} " <<
            "time=#{@time} timed_out=#{timed_out?}>"
    end
    alias :inspect :to_s

end

end
end
end
