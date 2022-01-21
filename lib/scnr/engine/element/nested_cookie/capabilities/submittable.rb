=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Element
class NestedCookie
module Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Submittable
    include SCNR::Engine::Element::Capabilities::Submittable

    def submit( options = {}, &block )
        options                   = options.dup
        options[:raw_cookies]     = [self]
        options[:follow_location] = true if !options.include?( :follow_location )

        @auditor ||= options.delete( :auditor )

        options[:performer] ||= self

        options[:raw_parameters] ||= raw_inputs

        http_request( options, &block )
    end

end

end
end
end
