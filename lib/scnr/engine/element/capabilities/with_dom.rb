=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module WithDOM

    # @return     [DOM]
    attr_accessor :dom

    # @return     [Bool, nil]
    #   Force {#dom} to return `nil` -- used as an audit optimization.
    attr_accessor :skip_dom

    # @return   [DOM]
    def dom
        return if skip_dom?
        @dom ||= self.class::DOM.new( parent: self )
    rescue Inputtable::Error => e
        print_debug_exception e
        nil
    end

    def skip_dom=( bool )
        @dom      = nil if bool
        @skip_dom = bool
    end

    def skip_dom?
        !!@skip_dom
    end

    def dup
        copy_with_dom( super )
    end

    private

    def copy_with_dom( other )
        other.dom      = @dom.dup.tap { |d| d.parent = other } if @dom
        other.skip_dom = @skip_dom
        other
    end

end

end
end
