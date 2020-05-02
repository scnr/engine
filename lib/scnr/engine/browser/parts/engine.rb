=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
module Parts

module Engine

    class Error < Browser::Error

        # Raised when given an unknown engine.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class UnknownEngine < Error
        end

    end

    # @return   [Engines::Base]
    attr_reader :engine

    def initialize
        super()

        e = @options[:engine] || Options.browser_cluster.engine

        klass = Engines.supported[e.to_sym]
        fail Error::UnknownEngine, "Unknown engine: #{e}" if !klass

        @engine = klass.new(
            self,
            {
                visible:     @options[:visible],
                width:       @options[:width],
                height:      @options[:height],
                pixel_ratio: @options[:pixel_ratio],
                user_agent:  @options[:user_agent],
                touch:       @options[:touch],

                request_handler:  proc do |request, response|
                    exception_jail { request_handler( request, response ) }
                end,
                response_handler: proc do |request, response|
                    exception_jail { response_handler( request, response ) }
                end
            }
        )
    end

    # @return   [Selenium::WebDriver::Driver]
    #   Selenium driver interface.
    def selenium
        engine.selenium
    end

    # @return   [Watir::Browser]
    #   Watir driver interface.
    def watir
        engine.watir
    end

    # @return   [String]
    #   HTML code of the evaluated (DOM/JS/AJAX) page with the
    #   {Browser::Javascript#remove_env_from_html JS env removed}.
    def source
        javascript.remove_env_from_html!( real_source )
    end

    # @return   [String]
    #   HTML code of the evaluated (DOM/JS/AJAX) page with the JS env modifications.
    def real_source
        selenium.page_source
    end

    # @return   [String]
    #   Prefixes each source line with a number.
    def source_with_line_numbers
        source.lines.map.with_index do |line, i|
            "#{i+1} - #{line}"
        end.join
    end

    def window_width
        engine.window_width
    end

    def window_height
        engine.window_height
    end

    def wait_till_ready
        @javascript.wait_till_ready
        engine.wait_for_pending_requests
    end

end

end
end
end
