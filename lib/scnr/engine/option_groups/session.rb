=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::OptionGroups

# Holds login options for the {Engine::Framework}'s {Engine::Session} manager.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Session < SCNR::Engine::OptionGroup

    # @return   [String]
    #   URL whose {Engine::HTTP::Response response} {Engine::HTTP::Message#body}
    #   should match {#check_pattern} when a valid webapp {SCNR::Engine::Session session}
    #   has been established.
    #
    # @see Session
    attr_accessor :check_url

    # @return   [Regexp]
    #   Pattern which should match the {#check_url} {SCNR::Engine::HTTP::Response response}
    #   {SCNR::Engine::HTTP::Message#body} when a valid webapp {Session session} has
    #   been established.
    #
    # @see Session
    attr_accessor :check_pattern

    def check_pattern=( pattern )
        return @check_pattern = nil if !pattern

        @check_pattern = Regexp.new( pattern )
    end

    def validate
        return {} if (check_url && check_pattern) || (!check_url && !check_pattern)

        {
            (check_url ? :check_pattern : :check_url) =>
                'Option is missing.'
        }
    end

    def to_rpc_data
        d = super
        d['check_pattern'] = d['check_pattern'].to_s if d['check_pattern']
        d
    end

end
end
