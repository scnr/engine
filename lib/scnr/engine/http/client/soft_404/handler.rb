=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module HTTP
class Client
class Soft404

class Handler
    include UI::Output

    CACHE = {
        url_for:                  1_000,
        needs_advanced_analysis?: 10_000
    }.inject({}) do |h, (name, size)|
        h.merge! name => Support::Cache::LeastRecentlyPushed.new( size: size )
    end

    include Support::Mixins::Parts

    class <<self

        def for( parent, url )
            new( parent, url_for( url ) )
        end

        def url_for( url )
            CACHE[__method__].fetch url do
                parsed = SCNR::Engine::URI( url )

                # If we're dealing with a file resource, then its parent directory will
                # be the applicable custom-404 handler...
                if parsed.resource_extension
                    trv_back = SCNR::Engine::URI( parsed.up_to_path ).path

                # ...however, if we're dealing with a directory, the applicable handler
                # will be its parent directory.
                else
                    trv_back = File.dirname( SCNR::Engine::URI( parsed.up_to_path ).path )
                end

                trv_back += '/' if trv_back[-1] != '/'

                parsed = parsed.dup
                parsed.path = trv_back
                parsed.to_s
            end
        end

        def needs_advanced_analysis?( url )
            CACHE[__method__].fetch url do
                uri = SCNR::Engine::URI( url )
                resource_name = uri.resource_name.to_s.split('.').tap(&:pop).join('.')

                !resource_name.empty? ||
                    uri.resource_extension ||
                    uri.resource_name.to_s.include?( '~' ) ||
                    uri.resource_name.to_s.include?( '-' )
            end
        end

    end

    def initialize( parent, url )
        @parent = parent
        @url    = url

        @analyzed  = false
        @corrupted = false
        @hard      = false

        @checks              = Concurrent::Array.new
        @basic_signatures    = Concurrent::Array.new
        @advanced_signatures = Concurrent::Array.new
    end

    def url
        @url
    end

    def schedule_check( response, &block )
        fail 'Corrupted, cannot check.' if corrupted?

        url       = response.request.url
        signature = (soft? ? response.body.signature : nil)

        print_debug "[waiting]: #{self.url} #{url} #{block}"

        @checks << [
            url,
            response.code,
            signature,
            block
        ]
    end

    def check( &block )
        fail 'Corrupted, cannot check.' if corrupted?
        return if !has_pending_checks?

        print_debug "[checking]: #{self.url} #{block}"

        # First taste, what are we dealing with? Hard/Soft?
        after_basic_analysis @checks.first.first do
            block.call if block

            if hard?
                check_as_hard
            else
                check_as_soft
            end
        end
    end

    def has_pending_checks?
        @checks.any?
    end

    def analyzed?
        @analyzed
    end

    def hard?
        @hard
    end

    def soft?
        !hard?
    end

    def corrupted?
        @corrupted
    end

    private

    def hard!
        @hard                = true
        @basic_signatures    = nil
        @advanced_signatures = nil
    end

    def analyzed!
        @analyzed = true
    end

    def corrupted!
        @corrupted           = true
        @basic_signatures    = nil
        @advanced_signatures = nil
    end

    def check_as_hard
        while (url, code, _, callback = @checks.pop)
            result = (code != 200)
            print_debug "[notify]: #{self.url} #{callback} #{url} #{result}"
            callback.call( result )
        end
    end

    def check_as_soft
        while (url, _, signature, callback = @checks.pop)

            result = matches_basic_signatures?( signature )
            print_debug "[checked]: #{self.url} #{callback} #{url} #{result}"

            if result || !self.class.needs_advanced_analysis?( url )
                print_debug "[notify]: #{self.url} #{callback} #{url} #{result}"
                callback.call( result )
                next
            end

            check_as_advanced( url, signature, &callback )
        end
    end

    def check_as_advanced( url, signature, &block )
        after_advanced_analysis url do

            result = matches_advanced_signatures?( signature )

            print_debug "[notify]: #{self.url} #{block} #{url} #{result}"
            block.call result

            # More checks may have been added during the advanced analysis.
            @parent.schedule_handler( self ) if has_pending_checks?
        end
    end

end

end
end
end
end
