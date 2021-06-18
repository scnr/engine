=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class BrowserPool
module Jobs
class DOMExploration

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Result < Job::Result

    # @return [Page]
    attr_accessor :page

    def to_s
        "#<#{self.class}:#{object_id} @job=#{@job} @page=#{@page}>"
    end

end

end
end
end
end
