=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine Framework project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine Framework
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class State

class Trainer

    # @return   [Support::Filter::Set]
    attr_reader :seen_responses_filter

    def initialize
        @seen_responses_filter = Support::Filter::Set.new(hasher: :persistent_hash )
    end

    # @param    [String]  key
    #
    # @return    [Bool]
    #   `true` if the `page` has already been seen (based on the
    #   {#seen_responses_filter}), `false` otherwise.
    #
    # @see #page_seen
    def response_seen?( key )
        @seen_responses_filter.include? key
    end

    # @param    [String]  key
    #   Page to mark as seen.
    #
    # @see #page_seen?
    def response_seen( key )
        @seen_responses_filter << key
    end

    def statistics
        {
            seen_responses_filter: @seen_responses_filter.size
        }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        %w(seen_responses_filter).each do |attribute|
            IO.binwrite( "#{directory}/#{attribute}", Marshal.dump( send(attribute) ) )
        end
    end

    def self.load( directory )
        trainer = self.new

        %w(seen_responses_filter).each do |attribute|
            path = "#{directory}/#{attribute}"
            next if !File.exist?( path )

            trainer.send(attribute).merge Marshal.load( IO.binread( path ) )
        end

        trainer
    end

    def clear
        @seen_responses_filter.clear
    end

end

end
end
