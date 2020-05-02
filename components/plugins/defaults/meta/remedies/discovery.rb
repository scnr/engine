=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Catches soft-404s that somehow slipped past the {HTTP::Client::Soft404}
# (or similar server behavior) that can confuse discovery checks.
#
# This is relatively easy to determine since valid responses to discovery checks
# should vary wildly, while soft-404 responses will have many commonalities
# every time.
#
# This is a sort of baseline implementation/anomaly detection.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Plugins::Discovery < SCNR::Engine::Plugin::Base

    def run
        wait_while_framework_running

        # URL path => Issue hashes.
        issue_digests_per_path = {}

        # URL path => Support::Signature of response bodies.
        signatures_per_path  = {}

        # URL path => size of response bodies.
        response_size_per_path  = {}

        issue_count_per_path = {}

        Data.issues.each do |issue|
            next if !issue.tags.includes_tags?( :discovery )

            # Skip it if already flagged as untrusted.
            next if issue.untrusted?

            # We'll do this per path since 404 handlers and such operate per
            # directory...usually...probably...hopefully.
            path = File.dirname( uri_parse( issue.vector.action ).path )

            issue_count_per_path[path] ||= 0
            issue_count_per_path[path]  += 1

            # Gather total response sizes per path.
            response_size_per_path[path] ||= 0
            response_size_per_path[path]  += issue.response.body.size

            # Categorize issues per path as well.
            issue_digests_per_path[path] ||= []
            issue_digests_per_path[path] << issue.digest

            # Extract the static parts of the responses in order to determine
            # how much of them doesn't change between requests.
            #
            # Large deviations between responses are good because it means that
            # we're not dealing with some custom not-found response (or something
            # similar) as these types of responses stay pretty similar.
            #
            # On the other hand, valid responses will be dissimilar since the
            # discovery checks look for different things.
            signatures_per_path[path] = Support::Signature.for_or_refine(
                signatures_per_path[path],
                issue.response.body
            )
        end

        signatures_per_path.each_pair do |path, signature|
            # Not a lot of sense in comparing a single issue with itself.
            next if issue_count_per_path[path] <= 1

            # Calculate the similarity ratio of the responses under the current path.
            similarity = Float( signature.size * issue_digests_per_path[path].size ) /
                response_size_per_path[path]

            SCNR::Engine::Element::Server.flag_issues_if_untrusted(
                similarity, issue_digests_per_path[path]
            )
        end
    end

    def self.info
        {
            name:        'Discovery-check response anomalies',
            description: %q{
Analyzes the scan results and identifies issues logged by discovery checks
(i.e. checks that look for certain files and folders on the server),
while the server responses were exhibiting an anomalous factor of similarity.

There's a good chance that these issues are false positives.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.3.3',
            tags:        %w(anomaly discovery file directories meta)
        }
    end

end
