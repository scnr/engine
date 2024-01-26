=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Reporter

# Provides some common options for the reports.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Options
    include Component::Options

    # Returns a string option named `outfile`.
    #
    # Default value is:
    #   year-month-day hour.minute.second +timezone.extension
    #
    # @param    [String]    extension     Extension for the outfile.
    # @param    [String]    description   Description of the option.
    #
    # @return   [SCNR::Engine::OptString]
    def outfile( extension = '', description = 'Where to save the report.' )
        Options::String.new( :outfile,
                             description: description,
                             default:     Time.now.to_s.gsub( ':', '_' ) + extension
        )
    end

    extend self
end
end
end
