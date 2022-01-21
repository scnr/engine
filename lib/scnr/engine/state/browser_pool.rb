=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class State

# State information for {SCNR::Engine::BrowserPool}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class BrowserPool
    include MonitorMixin

    # @return     [Hash]
    attr_reader   :job_callbacks

    # @return     [Hash]
    attr_reader   :pending_jobs

    # @return    [Integer]
    attr_accessor :pending_job_counter

    # @return    [Integer]
    attr_accessor :job_id

    # @return    [Integer]
    attr_accessor :total_job_time

    # @return    [Integer]
    attr_accessor :completed_job_count

    # @return    [Integer]
    attr_accessor :queued_job_count

    # @return    [Integer]
    attr_accessor :time_out_count

    def initialize
        super()

        @job_callbacks       = {}
        @pending_jobs        = Hash.new(0)
        @pending_job_counter = 0
        @job_id              = 0

        @queued_job_count    = 0
        @completed_job_count = 0
        @time_out_count      = 0
        @total_job_time      = 0.0
    end

    def add_to_total_job_time( time )
        synchronize { @total_job_time += time.to_f }
    end

    def increment_time_out_count
        synchronize { @time_out_count += 1 }
    end

    def increment_completed_job_count
        synchronize { @completed_job_count += 1 }
    end

    def increment_queued_job_count
        synchronize { @queued_job_count += 1 }
    end

    def increment_job_id
        synchronize { @job_id += 1 }
    end

    def statistics
        {
            pending_job_counter: @pending_job_counter,
            total_job_time:      @total_job_time,
            time_out_count:      @time_out_count,
            completed_job_count: @completed_job_count,
            queued_job_count:    @queued_job_count
        }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        %w(pending_jobs pending_job_counter job_id total_job_time time_out_count
            completed_job_count queued_job_count).each do |attribute|
            IO.binwrite( "#{directory}/#{attribute}", Marshal.dump( send(attribute) ) )
        end

        jc = {}
        @job_callbacks.each do |id, method|
            jc[id] = [method.receiver, method.name]
        end

        IO.binwrite( "#{directory}/job_callbacks", Marshal.dump( jc ) )
    end

    def self.load( directory )
        browser_pool = new

        %w(pending_jobs).each do |attribute|
            path = "#{directory}/#{attribute}"
            next if !File.exist?( path )

            browser_pool.send(attribute).merge! Marshal.load( IO.binread( path ) )
        end

        Marshal.load( IO.binread( "#{directory}/job_callbacks" ) ).each do |id, m|
            browser_pool.job_callbacks[id] = m.first.method( m.last )
        end

        %w(pending_job_counter job_id total_job_time time_out_count
            completed_job_count queued_job_count).each do |attribute|
            path = "#{directory}/#{attribute}"
            next if !File.exist?( path )

            browser_pool.send( "#{attribute}=", Marshal.load( IO.binread( path ) ) )
        end

        browser_pool
    end

    def clear
        @job_callbacks.clear
        @pending_jobs.clear

        @pending_job_counter = 0
        @job_id              = 0
        @queued_job_count    = 0
        @completed_job_count = 0
        @time_out_count      = 0
        @total_job_time      = 0.0
    end

end

end
end
