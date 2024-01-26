=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Extracts meta refresh URLs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Parser::Extractors::MetaRefresh < SCNR::Engine::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'http-equiv' )

        paths = []
        document.nodes_by_attribute_name_and_value( 'http-equiv', 'refresh' ) do |url|
            begin
                _, url = url['content'].split( ';', 2 )
                next if !url

                paths << unquote( url.split( '=', 2 ).last.strip )
            rescue
                next
            end
        end
        paths
    end

    def unquote( str )
        [ '\'', '"' ].each do |q|
            return str[1...-1] if str.start_with?( q ) && str.end_with?( q )
        end
        str
    end

end
