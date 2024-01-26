=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require_relative 'engines/base'

module SCNR::Engine
class Browser
class Engines

    class Error < Browser::Error
    end

    class<<self

        def supported
            @supported ||= {}
        end

        def register( engine )
            name = Utilities.caller_name.to_sym
            engine.name = name

            supported[engine.name] = engine
        end

    end

    Dir.glob( "#{File.dirname(__FILE__)}/engines/*.rb" ).each do |engine|
        require engine
    end

    if Options.dom.class::ENGINES.sort != supported.keys.sort
        fail "#{Options.dom.class}::ENGINES doesn't match #{self}."
    end

end
end
end
