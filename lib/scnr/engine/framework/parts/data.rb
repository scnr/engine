=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Framework
module Parts

# Provides access to {SCNR::Engine::Data::Framework} and helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Data

    class <<self

        # @param    [Page]  page
        #   Page to push to the page audit queue -- increases {#page_queue_total_size}
        #
        # @return   [Bool]
        #   `true` if push was successful, `false` if the `page` matched any
        #   exclusion criteria or has already been seen.
        def push_to_page_queue( page, force = false )
            if !force && (
              !Framework.accepts_more_pages? || Framework.state.page_seen?( page ) ||
                page.scope.out? || page.scope.redundant?( true )
            )
                page.clear_cache
                return false
            end

            # We want to update from the already loaded page cache (if there is one)
            # as we have to store the page anyways (needs to go through Browser analysis)
            # and it's not worth the resources to parse its elements.
            #
            # We're basically doing this to give the Browser and Trainer a better
            # view of what elements have been seen, so that they won't feed us pages
            # with elements that they think are new, but have been provided to us by
            # some other component; however, it wouldn't be the end of the world if
            # that were to happen.
            ElementFilter.update_from_page_cache page

            Framework.data.push_to_page_queue page
            Framework.state.page_seen page

            true
        end
    end

    # How many times to request a page upon failure.
    PAGE_MAX_TRIES = 5
    
    # @return   [Data::Framework]
    def data
        SCNR::Engine::Data.framework
    end

    def push_to_page_queue( *args )
        self.class::Parts::Data.push_to_page_queue( *args )
    end

    # @param    [String]  url
    #   URL to push to the audit queue -- increases {#url_queue_total_size}
    #
    # @return   [Bool]
    #   `true` if push was successful, `false` if the `url` matched any
    #   exclusion criteria or has already been seen.
    def push_to_url_queue( url, force = false )
        return if !force && !accepts_more_pages?

        url = to_absolute( url ) || url
        if state.url_seen?( url ) || skip_path?( url ) || redundant_path?( url, true )
            return false
        end

        data.push_to_url_queue url
        state.url_seen url

        true
    end

    # @return   [Integer]
    #   Total number of pages added to the {#push_to_page_queue page audit queue}.
    def page_queue_total_size
        data.page_queue_total_size
    end

    # @return   [Integer]
    #   Total number of URLs added to the {#push_to_url_queue URL audit queue}.
    def url_queue_total_size
        data.url_queue_total_size
    end

    # @return   [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    def sitemap
        data.sitemap
    end

    private

    def page_queue
        data.page_queue
    end

    def url_queue
        data.url_queue
    end

    def has_audit_workload?
        !url_queue.empty? || !page_queue.empty?
    end

    # @return   [Page, nil]
    #   A page if the queues aren't empty, `nil` otherwise.
    def pop_page
        pop_page_from_queue || pop_page_from_url_queue
    end

    # @return   [Page, nil]
    #   A page if the queue wasn't empty, `nil` otherwise.
    def pop_page_from_url_queue( &block )
        url = nil

        # Scope may have changed since the URL was pushed.
        loop do
            return if url_queue.empty?

            url = url_queue.pop
            break if !skip_path?( url )
        end

        grabbed_page = nil
        Page.from_url( url, http: {
               update_cookies: true,
               performer:      self
           }
        ) do |page|
            @retries[page.url.hash] ||= 0

            if (location = page.response.headers.location)
                [location].flatten.each do |l|
                    print_info "Scheduled #{page.code} redirection: #{page.url} => #{l}"
                    push_to_url_queue to_absolute( l, page.url )
                end
            end

            if page.code != 0
                grabbed_page = page
                @retries.delete page.url.hash
                block.call grabbed_page if block_given?
                next
            end

            if @retries[page.url.hash] >= PAGE_MAX_TRIES
                @failures << page.url

                print_error "Giving up trying to audit: #{page.url}"
                print_error "Couldn't get a response after #{PAGE_MAX_TRIES}" +
                                " tries: #{page.response.return_message}."
            else
                print_bad "Retrying for: #{page.url} [#{page.response.return_message}]"
                @retries[page.url.hash] += 1
                url_queue << page.url
            end

            grabbed_page = nil
            block.call grabbed_page if block_given?
        end

        http.run if !block_given?
        grabbed_page
    end

    # @return   [Page, nil]
    #   A page if the queue wasn't empty, `nil` otherwise.
    def pop_page_from_queue
        page = nil

        # Scope may have changed since the page was pushed.
        loop do
            return if page_queue.empty?

            page = page_queue.pop
            break if !page.scope.out?
        end

        page
    end

    def replenish_page_queue_from_url_queue
        return if !page_queue.empty?

        # Number pulled out of my ass, low enough to not add any noticeable
        # stress, hopefully high enough to grab us at least one page that has
        # some workload which will result in HTTP requests which will mask the
        # next replenishing operation.
        10.times do
            break if url_queue.empty?

            # We push directly to the queue instead of using #push_to_page_queue
            # because it's too early to deduplicate.
            pop_page_from_url_queue { |p| page_queue << p if p }
        end

        http.run

        true
    end

    def add_to_sitemap( page )
        data.add_page_to_sitemap( page )
    end

    def update_sitemap( entries )
        data.update_sitemap( entries )
    end

    def push_paths_from_page( page )
        if state.page_paths_seen? page
            print_debug 'Paths already seen.'
            return []
        end
        state.page_paths_seen page

        page.paths.select { |path| push_to_url_queue( path ) }
    end

end

end
end
end
