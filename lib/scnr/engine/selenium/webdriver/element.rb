=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module Selenium
module WebDriver
class Element

    def html
        @bridge.execute_script( 'return arguments[0].outerHTML', self )
    end

    def opening_tag
        @bridge.execute_script(
            %Q[
                var s = '<' + arguments[0].tagName.toLowerCase();
                var attrs = arguments[0].attributes;
                for( var l = 0; l < attrs.length; ++l ) {
                    s += ' ' + attrs[l].name + '="' + attrs[l].value.replace( '"', '\"' ) + '"';
                }
                s += '>'
                return s;
            ],
            self
        )
    end

end
end
end
