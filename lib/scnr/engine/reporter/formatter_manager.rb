=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Reporter

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class FormatterManager < Component::Manager
    def paths
        @paths_cache ||=
            Dir.glob( File.join( "#{@lib}", '*.rb' ) ).
                reject { |path| helper?( path ) }
    end
end

end
end
