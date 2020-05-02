=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::Stdout

# Stdout formatter for the results of the HTTPDicattack plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::HTTPDicattack < SCNR::Engine::Plugin::Formatter

    def run
        print_info 'Cracked credentials:'
        print_ok "    Username: '#{results['username']}'"
        print_ok "    Password: '#{results['password']}'"
    end

end

end
