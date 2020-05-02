=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::HTML

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::UncommonHeaders < SCNR::Engine::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
        <ul>
        <% results.each do |url, headers| %>
            <li>
                <a href="<%= escapeHTML url %>"><%= escapeHTML url %></a>

                <dl class="dl-horizontal">
                    <% headers.each do |name, value| %>
                        <dt><%= escapeHTML name %></dt>
                        <dd><code><%= escapeHTML value %></code></dd>
                    <% end %>
                </dl>

            </li>
        <% end %>
        </ul>
        HTML
    end

end
end
