=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Data
class Framework

# Data for {SCNR::Engine::RPC::Server::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class RPC

    # @return   [Support::Database::Queue]
    attr_reader :distributed_page_queue

    def initialize
        @distributed_page_queue = Support::Database::Queue.new
    end

    def statistics
        { distributed_page_queue: @distributed_page_queue.size }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        page_queue_directory = "#{directory}/distributed_page_queue/"

        FileUtils.rm_rf( page_queue_directory )
        FileUtils.mkdir_p( page_queue_directory )

        distributed_page_queue.buffer.each do |page|
            File.open(
                "#{page_queue_directory}/#{page.persistent_hash}", 'wb' ) do |f|
                distributed_page_queue.serialize( page, f )
            end
        end

        distributed_page_queue.disk.each do |filepath|
            FileUtils.cp filepath, "#{page_queue_directory}/"
        end
    end

    def self.load( directory )
        rpc = new

        Dir["#{directory}/distributed_page_queue/*"].each do |page_file|
            rpc.distributed_page_queue.disk << page_file
        end

        rpc
    end

    def clear
        @distributed_page_queue.clear
    end

end

end
end
end
