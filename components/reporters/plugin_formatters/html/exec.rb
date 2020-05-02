=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::HTML

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::Exec < SCNR::Engine::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
        <ul class="nav nav-tabs">
            <% results.keys.each.with_index do |stage, i| %>
                <li <%= 'class="active"' if i == 0 %> >
                    <a href="#!/plugins/exec/<%= stage %>">
                        <%= stage.capitalize %>
                    </a>
                </li>
            <% end %>
        </ul>

        <div class="tab-content">
            <% results.each do |stage, data| %>
                <div class="tab-pane <%= 'active' if results.keys.first == stage %>"
                    id="plugins-exec-<%= stage %>">

                    <dl class="dl-horizontal">
                        <dt>Executable</dt>
                        <dd><code><%= escapeHTML data['executable'] %></code></dd>

                        <dt>Status</dt>
                        <dd><%= data['status'] %></dd>

                        <dt>PID</dt>
                        <dd><%= data['pid'] %></dd>

                        <dt>Runtime</dt>
                        <dd><%= data['runtime'] %></dd>
                    </dl>

                    <strong>STDOUT</strong>
                    <pre><%= escapeHTML data['stdout'].to_s %></pre>

                    <strong>STDERR</strong>
                    <pre><%= escapeHTML data['stderr'].to_s %></pre>
                </div>
            <% end %>
        </div>
        HTML
    end

end

end
