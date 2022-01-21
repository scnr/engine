=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR
module Engine

# It provides a namespace for all system errors.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Error < StandardError

    class <<self
        def on_new( &block )
            on_new_blocks << block
        end

        def notify_on_new( e )
            on_new_blocks.each do |b|
                b.call e
            end
        end

        def on_new_blocks
            @on_new_blocks ||= []
        end
    end

    def initialize(*)
        super

        self.set_backtrace caller
        Error.notify_on_new( self )
    end

end

end
end
