=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::HTML

# HTML formatter for the results of the CookieCollector plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::CookieCollector < SCNR::Engine::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <ul>
            <% results.each do |entry| %>
                <li>
                    On <strong><%= entry['time'] %></strong> by

                    <a href="<%= escapeHTML entry['response']['url'] %>">
                        <%= escapeHTML entry['response']['url'] %>
                    </a>

                    <ul>
                        <% (entry['response']['headers']['Set-Cookie'] || []).each do |set_cookie| %>
                            <li>
                                <code><%= escapeHTML set_cookie %></code>
                            </li>
                        <% end %>
                    </ul>
                </li>
            <% end %>
            </ul>
        HTML
    end

end
end
