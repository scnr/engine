=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# MultipleChoice option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Component::Options::MultipleChoice < SCNR::Engine::Component::Options::Base

    # The list of potential valid values
    attr_accessor :choices

    def initialize( name, options = {} )
        options  = options.dup
        @choices = [options.delete(:choices)].flatten.compact.map(&:to_s)
        super
    end

    def normalize
        super.to_s
    end

    def valid?
        return false if !super
        choices.include?( effective_value )
    end

    def description
        "#{@description} (accepted: #{choices.join( ', ' )})"
    end

    def type
        :multiple_choice
    end

end
