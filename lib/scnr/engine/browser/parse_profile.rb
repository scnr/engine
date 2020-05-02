=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Browser

# Page parsing profile for {Browser::Parts::Snapshots#to_page}.
class ParseProfile

    ATTRIBUTES = [
        # Sets {Page#body} to {Browser#source}.
        :body,

        # Sets page elements from DOM.
        :elements,

        # Sets {Page::DOM#cookies} to {Browser#cookies}.
        :cookies,

        # Sets {Page::DOM#digest} to {Browser::Javascript#dom_digest}.
        :digest,

        # Sets {Page::DOM#execution_flow_sinks} to {Browser::Javascript#execution_flow_sinks}.
        :execution_flow_sinks,

        # Sets {Page::DOM#data_flow_sinks} to {Browser::Javascript#data_flow_sinks}.
        :data_flow_sinks,

        # Sets {Page::DOM#skip_states}.
        :skip_states
    ]

    ATTRIBUTES.each do |v|
        attr_accessor v
    end

    def initialize( options = {} )
        ATTRIBUTES.each do |k|
            send( "#{k}=", true )
        end

        update( options )
    end

    def only( *args )
        options = ATTRIBUTES.inject({}) { |h, k| h.merge k => false }
        args.each { |k| options[k] = true }

        update options
    end

    def except( *args )
        options = ATTRIBUTES.inject({}) { |h, k| h.merge k => true }
        args.each { |k| options[k] = false }

        update options
    end

    def update( options )
        options.each do |k, v|
            send( "#{k}=", v )
        end

        self
    end

    def disable!
        ATTRIBUTES.each do |k|
            send( "#{k}=", false )
        end

        self
    end

    def disabled?
        !ATTRIBUTES.find { |k| send k }
    end

    def hash
        ATTRIBUTES.inject({}) { |h, k| h.merge k => send( k ) }.hash
    end

    def ==( other )
        hash == other.hash
    end

    class <<self

        def only( *args )
            new.only( *args )
        end

        def except( *args )
            new.except( *args )
        end

        def disable!
            new.disable!
        end

    end

end

end
end
