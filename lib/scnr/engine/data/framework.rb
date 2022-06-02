=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'msgpack'

module SCNR::Engine
class Data

# Data for {SCNR::Engine::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Framework
    include Support::Mixins::Observable

    advertise :on_page
    advertise :on_url
    advertise :on_sitemap_entry

    # {Framework} error namespace.
    #
    # All {Framework} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Data::Error
    end

    # @return     [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    attr_reader   :sitemap

    # @return     [Support::Database::Queue]
    attr_reader   :page_queue

    # @return     [Integer]
    attr_accessor :page_queue_total_size

    # @return     [Support::Database::Queue]
    attr_reader   :url_queue

    # @return     [Integer]
    attr_accessor :url_queue_total_size

    def initialize
        super

        @sitemap = {}

        @page_queue = Support::Database::Queue.new
        @page_queue_total_size = 0

        @url_queue = ::Queue.new
        @url_queue_total_size = 0
    end

    def statistics
        {
            sitemap:               @sitemap.size,
            page_queue:            @page_queue.size,
            page_queue_total_size: @page_queue_total_size,
            url_queue:             @url_queue.size,
            url_queue_total_size:  @url_queue_total_size
        }
    end

    # @note Increases the {#page_queue_total_size}.
    #
    # @param    [Page]  page
    #   Page to push to the {#page_queue}.
    def push_to_page_queue( page )
        page.clear_cache
        notify_on_page( page )

        @page_queue << page
        add_page_to_sitemap( page )
        @page_queue_total_size += 1
    end

    # @note Increases the {#url_queue_total_size}.
    #
    # @param    [String]  url
    #   URL to push to the {#url_queue}.
    def push_to_url_queue( url )
        notify_on_url( url )

        @url_queue << url
        @url_queue_total_size += 1
    end

    # @param    [Page]  page
    #   Page with which to update the {#sitemap}.
    def add_page_to_sitemap( page )
        update_sitemap( page.dom.url => page.code )
    end

    def update_sitemap( entries )
        entries.each do |url, code|
            # Feedback from the trainer or whatever, don't include it in the
            # sitemap, it'll just add noise.
            next if url.include?( Utilities.random_seed )

            notify_on_sitemap_entry( url => code )

            @sitemap[url] = code
        end

        @sitemap
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        page_queue_directory = "#{directory}/page_queue/"

        FileUtils.rm_rf( page_queue_directory )
        FileUtils.mkdir_p( page_queue_directory )

        page_queue.buffer.each do |page|
            File.open(
                "#{page_queue_directory}/#{page.persistent_hash}",
                'wb'
            ) do |f|
                page_queue.serialize( page, f )
            end
        end

        page_queue.disk.each do |filepath|
            FileUtils.cp filepath, "#{page_queue_directory}/"
        end

        IO.binwrite( "#{directory}/url_queue", Marshal.dump( @url_queue.buffer ) )

        %w(sitemap page_queue_total_size url_queue_total_size).each do |attribute|
            IO.binwrite( "#{directory}/#{attribute}", Marshal.dump( send(attribute) ) )
        end
    end

    def self.load( directory )
        framework = new

        framework.sitemap.merge! Marshal.load( IO.binread( "#{directory}/sitemap" ) )

        Dir["#{directory}/page_queue/*"].each do |page_file|
            framework.page_queue.disk << page_file
        end

        Marshal.load( IO.binread( "#{directory}/url_queue" ) ).each do |url|
            framework.url_queue.buffer << url
        end

        framework.page_queue_total_size =
            Marshal.load( IO.binread( "#{directory}/page_queue_total_size" ) )
        framework.url_queue_total_size =
            Marshal.load( IO.binread( "#{directory}/url_queue_total_size" ) )

        framework
    end

    def clear
        @sitemap.clear

        @page_queue.clear
        @page_queue_total_size = 0

        @url_queue.clear
        @url_queue_total_size = 0
    end

end

end
end
