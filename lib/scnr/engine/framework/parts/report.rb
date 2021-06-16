=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Framework
module Parts

# Provides a {SCNR::Engine::Report::Manager} and related helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Report

    # @return   [SCNR::Engine::Reporter::Manager]
    attr_reader :reporters

    def initialize
        super

        # Deep clone the redundancy rules to preserve their original counters
        # for the reports.
        @original_redundant_path_patterns =
          Options.scope.redundant_path_patterns.deep_clone

        @reporters = SCNR::Engine::Reporter::Manager.new
    end

    # @return    [SCNR::Engine::Report]
    #   Scan results.
    def report
        opts = Options.to_hash.deep_clone

        # restore the original redundancy rules and their counters
        opts[:scope][:redundant_path_patterns] = @original_redundant_path_patterns

        SCNR::Engine::Report.new(
            status:          state.status,
            options:         Options,
            sitemap:         sitemap.dup,
            issues:          SCNR::Engine::Data.issues.sort,
            plugins:         @plugins.results,
            start_datetime:  @start_datetime,
            finish_datetime: @finish_datetime
        )
    end

    # Runs a reporter component and returns the contents of the generated report.
    #
    # Only accepts reporters which support an `outfile` option.
    #
    # @param    [String]    name
    #   Name of the reporter component to run, as presented by {#list_reporters}'s
    #   `:shortname` key.
    # @param    [Report]    external_report
    #   Report to use -- defaults to the local one.
    #
    # @return   [String]
    #   Scan report.
    #
    # @raise    [Component::Error::NotFound]
    #   If the given reporter name doesn't correspond to a valid reporter component.
    #
    # @raise    [Component::Options::Error::Invalid]
    #   If the requested reporter doesn't format the scan results as a String.
    def report_as( name, external_report = report )
        if !@reporters.available.include?( name.to_s )
            fail Component::Error::NotFound, "Reporter '#{name}' could not be found."
        end

        loaded = @reporters.loaded
        begin
            @reporters.clear

            if !@reporters[name].has_outfile?
                fail Component::Options::Error::Invalid,
                     "Reporter '#{name}' cannot format the audit results as a String."
            end

            outfile = "#{Options.paths.tmpdir}/#{generate_token}"
            @reporters.run( name, external_report, outfile: outfile )

            IO.binread( outfile )
        rescue SCNR::Engine::Component::Error
            raise
        rescue => e
            print_exception e
        ensure
            File.delete( outfile ) if outfile && File.exists?( outfile )
            @reporters.clear
            @reporters.load loaded
        end
    end

    # @return    [Array<Hash>]
    #   Information about all available {Reporters}.
    def list_reporters( patterns = nil )
        loaded = @reporters.loaded

        begin
            @reporters.clear
            @reporters.available.map do |report|
                path = @reporters.name_to_path( report )
                next if patterns && !@reporters.matches_globs?( path, patterns )

                @reporters[report].info.merge(
                    options:   @reporters[report].info[:options] || [],
                    shortname: report,
                    path:      path,
                    author:    [@reporters[report].info[:author]].
                                   flatten.map { |a| a.strip }
                )
            end.compact
        ensure
            @reporters.clear
            @reporters.load loaded
        end
    end

end

end
end
end
