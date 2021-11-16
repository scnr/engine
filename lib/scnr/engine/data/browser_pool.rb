=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Data

# Data for {SCNR::Engine::BrowserPool}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class BrowserPool

    # @return  [Support::Database::Queue]
    attr_reader :job_queue

    def initialize
        @job_queue = Support::Database::CategorizedQueue.new( max_buffer_size: 10 )
    end

    def statistics
        {
            job_queue_size: @job_queue.size
        }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        job_queue_directory = "#{directory}/job_queue/"

        FileUtils.rm_rf( job_queue_directory )
        FileUtils.mkdir_p( job_queue_directory )

        job_queue.categories.each do |category|
            category_filepath = "#{job_queue_directory}/#{category}::"

            data = job_queue.data_for( category )

            data[:disk].each do |file|
                FileUtils.cp file, "#{category_filepath}#{File.basename( file )}"
            end

            data[:buffer].each.with_index do |job, i|
                File.open( "#{category_filepath}#{i}", 'wb' ) do |f|
                    job_queue.serialize( job, f )
                end
            end
        end
    end

    def self.load( directory )
        framework = new

        Dir["#{directory}/job_queue/*"].each do |file|
            category = file.split( '/' ).last.split( '::' ).first
            framework.job_queue.insert_to_disk( category, file )
        end

        framework
    end

    def clear
        @job_queue.clear
    end

end

end
end
