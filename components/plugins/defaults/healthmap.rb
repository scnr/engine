=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Generates a simple list of safe/unsafe URLs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Plugins::HealthMap < SCNR::Engine::Plugin::Base

    def run
        wait_while_framework_running

        report = framework.report

        sitemap  = report.sitemap.keys.map { |url| url.split( '?' ).first }.uniq
        sitemap |= issue_urls = report.issues.map { |issue| issue.vector.action }.uniq

        return if sitemap.size == 0

        issue_cnt = 0
        map = []
        sitemap.sort.each do |url|
            next if !url

            if issue_urls.include?( url )
                map << { 'with_issues' => url }
                issue_cnt += 1
            else
                map << { 'without_issues' => url }
            end
        end

        register_results(
            'map'              => map,
            'total'            => map.size,
            'without_issues'   => map.size - issue_cnt,
            'with_issues'      => issue_cnt,
            'issue_percentage' => ((issue_cnt.to_f / map.size.to_f) * 100).round
        )
    end

    def self.info
        {
            name:        'Health map',
            description: %q{Generates a simple list of safe/unsafe URLs.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.5'
        }
    end

end
