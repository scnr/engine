=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Support::LookUp

# Lightweight look-up Set implementation.
#
# It uses stores hashes of items instead of the items themselves.
#
# This leads to decreased memory consumption and faster comparisons during look-ups.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Hash < Base

    require_relative 'hash/collection'

    # @param    (see Base#initialize)
    def initialize(*)
        super
        @collection = Collection.new
    end

    def merge( other )
        case other
            when self.class
                other.collection.each do |k, _|
                    @collection << k
                end

            when Set, Array
                other.each do |k|
                    self << k
                end

            else
                fail ArgumentError,
                     "Don't know how to merge with: #{other.class}"
        end

        self
    end

    [:replace].each do |m|
        define_method m do |other|
            @collection.send( m, other )
            self
        end
    end

end

end
end
