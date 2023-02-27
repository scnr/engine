=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class BrowserPool
class Job

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Result

    # @return [Job]
    attr_accessor :job

    # @param    [Hash]  options
    # @option   options [Job]   :job
    def initialize( options = {} )
        options.each { |k, v| send( "#{k}=", v ) }
    end

    def to_s
        "#{self.class.to_s.split( '::' ).last(2).join( '::' )} for job #{@job.id}"
    end

end

end
end
end
