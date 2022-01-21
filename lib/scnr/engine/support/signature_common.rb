=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::Support

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module SignatureCommon

    CACHE = {
        for:      1_000,
        refine:   1_000,
        similar?: 20_000
    }.inject({}) do |h, (name, size)|
        h.merge! name => Cache::LeastRecentlyPushed.new( size: size )
    end

    FAIL_IF_FROZEN = [:refine!, :clear, :<< ]

    def self.included( base )
        base.extend( ClassMethods )
    end

    module ClassMethods

        def self.extended( base )
            FAIL_IF_FROZEN.each do |m|
                base.instance_eval do
                    alias_method "_old_#{m}", m if method_defined? m

                    define_method m do |*args, &block|
                        fail "Can't modify frozen #{self.class}" if frozen?

                        if defined? super
                            super( *args, &block )
                        else
                            send "_old_#{m}", *args, &block
                        end

                    end
                end
            end
        end

        def for_or_refine( signature, data )
            signature ? refine( signature, data ) : self.for( data )
        end

        def for( string )
            CACHE[__method__].fetch( string ){ new( string ) }
        end

        def refine( *signatures )
            root, signatures = prepare_many_signatures( signatures )

            CACHE[__method__].fetch [root, signatures] do
                root = root.dup
                signatures.each { |s| root.refine!( s ) }
                root
            end
        end

        def similar?( threshold, *signatures )
            root, signatures = prepare_many_signatures( signatures )

            CACHE[__method__].fetch [root, signatures, threshold] do
                # If one is similar to the others, then the others will be
                # similar between them too.
                !signatures.find do |s|
                    !root.similar?( s, threshold )
                end
            end
        end

        private

        def prepare_many_signatures( signatures )
            signatures.flatten!

            if signatures.size < 2
                fail ArgumentError, 'Less than 2 signatures given.'
            end

            signatures.sort_by!(&:hash)

            # Strings may have gotten in there for refinement etc.
            root_idx = signatures.each.with_index { |s, i| break i if s.is_a? self }

            [signatures.delete_at( root_idx ), signatures]
        end

    end

end
end
