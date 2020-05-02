=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::HTML

# HTML formatter for the results of the HTTPDicattack plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::HTTPDicattack < SCNR::Engine::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <h3>Credentials</h3>

            <dl class="dl-horizontal">
                <dt>Username</dt>
                <dd><kbd><%= escapeHTML results['username'] %></kbd></dd>

                <dt>Password</dt>
                <dd><kbd><%= escapeHTML results['password'] %><kbd></dd>
            </dl>
        HTML
    end

end
end
