=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Reporters::HTML

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::SinkTracer < SCNR::Engine::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
    <strong>Seed</strong>: <code><%= results.first['mutation']['seed'] %></code>
    
    <h3>Reflected sinks</h3>
    <p>The seed was found present in the HTTP response or the DOM.</p>

    <ol>
    <% results.each do |entry| %>
        <% sinks = sinks_for( entry ) & %w(body header_name header_value) %>
        <% next if sinks.empty? %>

        <li>
            <%= render_entry( entry ) %>
        </li>
    <% end %>
    </ol>

    <h3>Active sinks</h3>
    <p>Functionality was activated in the web application.</p>

    <ol>
    <% results.each do |entry| %>
        <% next if !sinks_for( entry ).include?( 'active' ) %>

        <li>
            <%= render_entry( entry ) %>

            <% if entry['page'] && entry['page']['dom'] && (dfs = entry['page']['dom']['data_flow_sinks']).any? %>
                <strong>Data flow:</strong>
                <ol>
                    <% dfs.each.with_index do |df, idx| %>
                        <li>
                        <p><code><%= df['object'] %>.<%= df['function']['name'] %>( <%= escapeHTML df['function']['arguments'].join( ', ' ) %> )</code></p>
                        <ol>
                        <% df['trace'].each do |t| %>   
                            <% next if t['url'].include? 'javascript.browser.scnr.engine' %>
                            <li>
                                <code><%= t['function']['name'] %>()</code> at 
                                <a href="<%= escapeHTML t['url'] %>"><%= escapeHTML t['url'] %></a>:<%= t['line'] %>
                            </li>
                        <% end %>
                        </ol>
                        </li>

                        <%= code_highlight df['function']['source'], :javascript %>
                    <% end %>
                </ol>
            <% end %>
        </li>
    <% end %>
    </ol>

    <h3>Blind sinks</h3>
    <p>Could not discern functionality being activated in the web application.</p>

    <ol>
    <% results.each do |entry| %>
        <% next if !sinks_for( entry ).include?( 'blind' )%>

        <li>
            <%= render_entry( entry ) %>
        </li>
    <% end %>
    </ol>
        HTML
    end

    def render_entry( entry )
        html = <<-HTML
            <code><%= entry['mutation']['affected_input_name'] %></code>
            <%= entry['mutation']['type'] %> via
            <code><%= entry['mutation']['method'].upcase %></code>
            <a href="<%= escapeHTML entry['mutation']['action'] %>"><%= escapeHTML entry['mutation']['action'] %></a>
            using <code><%= entry['mutation']['inputs'][entry['mutation']['affected_input_name']].inspect %></code>
            <dl class="dl-horizontal">
                <% entry['mutation']['inputs'].each do |name, value| %>
                    <dt><%= escapeHTML name.inspect %></dt>
                    <dd><code><%= escapeHTML value.inspect %></code></dd>
                <% end %>
            </dl>
        HTML

        ERB.new( html ).result( binding )
    end

    def sinks_for( result )
        result['sinks'][result['mutation']['affected_input_name']]
    end

end
end
