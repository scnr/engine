=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'ostruct'

module SCNR::Engine::OptionGroups

# Generic OpenStruct-based class for general purpose data storage.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Datastore < SCNR::Engine::OptionGroup

    def initialize
        @source = OpenStruct.new
    end

    def method_missing( method, *args, &block )
        @source.send( method, *args, &block )
    end

    def to_h
        @source.marshal_dump
    end

end
end
