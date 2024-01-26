=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::OptionGroups

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Device < SCNR::Engine::OptionGroup

    VISIBLE     = false
    WIDTH       = 1600
    HEIGHT      = 1200
    USER_AGENT  = "Mozilla/5.0 (Gecko) SCNR::Engine/v#{SCNR::Engine::VERSION}"
    PIXEL_RATIO = 1.0
    TOUCH       = false

    # @note Default is {#VISIBLE}.
    #
    # @return   [Bool]
    attr_accessor :visible

    # @note Default is {#WIDTH}.
    #
    # @return   [Bool]
    #   Screen width.
    attr_accessor :width

    # @note Default is {#HEIGHT}.
    #
    # @return   [Bool]
    #   Screen height.
    attr_accessor :height

    # @note Default is {#USER_AGENT}.
    #
    # @return    [String]
    #   User-Agent to use.
    attr_accessor :user_agent

    # @note Default is {#PIXEL_RATIO}.
    #
    # @return   [Float]
    attr_accessor :pixel_ratio

    # @note Default is {#TOUCH}.
    #
    # @return   [Bool]
    attr_accessor :touch

    set_defaults(
        visible:     VISIBLE,
        width:       WIDTH,
        height:      HEIGHT,
        user_agent:  USER_AGENT,
        pixel_ratio: PIXEL_RATIO,
        touch:       TOUCH
    )

    def visible?
        !!@visible
    end

    def visible!
        @visible = true
    end

    def headless?
        !visible?
    end

    def headless!
        @visible = false
    end

    def touch!
        @touch = true
    end

    def touch?
        !!@touch
    end

end
end
