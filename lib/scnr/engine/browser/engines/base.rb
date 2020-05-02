=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser
class Engines

class Error < Browser::Error

    class IncompatibleVersion < Error
    end

end

class Base
    include UI::Output
    prepend Support::Mixins::SpecInstances

    class <<self

        def name
            @name
        end

        def name=( n )
            @name = n
        end

        # @private
        def inherited( engine )
            Engines.register engine
        end

    end

    include Support::Mixins::Parts

    # @return   [Browser]
    attr_reader :browser

    # @abstract
    def window_width
        raise 'Missing implementation'
    end

    # @abstract
    def window_height
        raise 'Missing implementation'
    end

    def touch?
        raise 'Missing implementation'
    end

    def version
        raise 'Missing implementation'
    end

    def initialize( browser, options = {} )
        @browser = browser

        @options                 = options.dup
        @options[:visible]       =
            (@options[:visible].nil? ? Options.device.visible? : @options[:visible])
        @options[:width]       ||= Options.device.width
        @options[:height]      ||= Options.device.height
        @options[:pixel_ratio] ||= Options.device.pixel_ratio
        @options[:user_agent]  ||= Options.device.user_agent
        @options[:touch]         =
            (@options[:touch].nil? ? Options.device.touch : @options[:touch])

        ensure_version_compatibility

        start
    end

    def name
        self.class.name
    end

    def reboot
        shutdown
        start
    end

    def user_agent
        browser.javascript.run( 'return navigator.userAgent' )
    end

    def pixel_ratio
        browser.javascript.run( 'return window.devicePixelRatio' )
    end

    def shutdown
        print_debug_level_2 'Shutting down...'

        if @proxy
            print_debug_level_2 'Shutting down proxy...'
            @proxy.shutdown rescue Arachni::Reactor::Error::NotRunning
            print_debug_level_2 '...done.'
        end

        kill

        @watir    = nil
        @selenium = nil
        @proxy    = nil
    end

    private

    def start
        start_webdriver
    end

    def ensure_version_compatibility
        self.class.requirements.each do |dependency, version|
            next if (version[:min] && version[:current] >= version[:min]) ||
                (version[:max] && version[:current] <= version[:max])

            fail Error::IncompatibleVersion,
                 "#{dependency} version is #{version[:current]} but " <<
                     "needs to be between #{version[:min].to_i} and #{version[:max] || 'later'}."
        end

        nil
    end

    def self._spec_instance_cleanup( i )
        i.shutdown
    end

end

end
end
end
