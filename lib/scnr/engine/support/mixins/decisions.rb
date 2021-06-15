=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module Support
module Mixins

module Decisions
    include UI::Output
    include Utilities

    def self.included( base )
        base.extend ClassMethods
    end

    module ClassMethods
        def query( *queries )
            queries.each do |query|
                define_method query do |&block|
                    add_decider( query, &block )
                end

                define_method "#{query}?" do |*args|
                    query_deciders( query, *args )
                end

                define_method "ask_#{query}?" do
                    deciders_for( query ).any?
                end
            end

            nil
        end
    end

    def initialize
        super if defined? super
        ask!
    end

    def ask!
        @__deciders = {}
        @__mutex    = Monitor.new
    end

    def reset
        synchronize { @__deciders.clear }
    end

    private

    def deciders
        @__deciders
    end

    def add_decider( event, &block )
        fail ArgumentError, 'Missing block' if !block
        synchronize do
            deciders_for( event ) << block
        end

        self
    end

    def query_deciders( event, *args )
        synchronize do
            !!deciders_for( event ).find do |block|
                block.call( *args )
            end
        end
    end

    def dup_deciders
        deciders.inject({}) { |h, (k, v)| h[k] = v.dup; h }
    end

    def set_deciders( obs )
        @__deciders = obs
    end

    def deciders_for( event )
        deciders[event.to_sym] ||= []
    end

    def clear_deciders
        synchronize do
            deciders.clear
        end
    end

    def synchronize( &block )
        @__mutex.synchronize( &block )
    end

end

end
end
end
