=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module HTTP
class Client
class Soft404
class Handler

    {
        matches_signatures?:     10_000,
        matches_signature_data?: 10_000
    }.each do |name, size|
        CACHE.merge! name => Support::Cache::LeastRecentlyPushed.new( size: size )
    end

module Parts
module Signature

    # Maximum allowed difference ratio when comparing custom 404 signatures.
    # The fact that we refine the signatures allows us to set this threshold
    # really low and still maintain good accuracy.
    SIMILARITY_THRESHOLD = 0.1

    # Maximum ratio of acceptable difference for response signatures.
    #
    # If response signatures for identical requests aren't similar enough, then
    # server behavior is considered too chaotic to analyze.
    DIFFERENCE_THRESHOLD = 0.3

    private

    def signature_from_url( url, signature_data, &block )
        precision = Parts::Analysis::PRECISION

        controlled_precision = precision * 2
        control_data         = {}
        gathered_responses   = 0

        controlled_precision.times do
            request( url ) do |response|
                next if corrupted?

                signature = gathered_responses >= precision ?
                                control_data : signature_data

                # Well, bad luck, bail out to avoid FPs.
                if corrupted_response?( response )
                    print_debug "[corrupted]: #{self.url} #{url} #{block}"
                    corrupted!
                    next
                end

                gathered_responses += 1

                if !signature[:original]
                    signature[:original] = response.body.signature
                    next
                end

                signature[:refined] = Support::Signature.refine(
                    signature[:refined] || signature[:original],
                    response.body
                )

                next if gathered_responses != controlled_precision

                # Both attempts yielded in the same result, the webapp was
                # stable during the process and the signature can be considered
                # accurate.
                if Support::Signature.similar?(
                    DIFFERENCE_THRESHOLD,
                    control_data[:refined],
                    signature_data[:refined]
                )
                    block.call response

                    # Coo-coo for cocoa puffs, can't work with it.
                else
                    print_debug "[corrupted]: #{self.url} #{url} #{block}"
                    corrupted!
                end
            end
        end
    end

    def matches_advanced_signatures?( signature )
        fail 'Empty advanced signatures.' if @advanced_signatures.empty?

        matches_signatures?( signature, @advanced_signatures )
    end

    def matches_basic_signatures?( signature )
        fail 'Empty basic signatures.' if @basic_signatures.empty?

        matches_signatures?( signature, @basic_signatures )
    end

    def matches_signatures?( signature, signatures )
        CACHE[__method__].fetch [signature, signatures] do
            !!signatures.find do |data|
                matches_signature_data?( signature, data )
            end
        end
    end

    def matches_signature_data?( signature, data )
        CACHE[__method__].fetch [data[:original], data[:refined], signature] do
            s = Support::Signature.refine( data[:original], signature )

            # If the signature is empty it means that they are completely
            # dissimilar.
            !s.empty? && Support::Signature.similar?(
                SIMILARITY_THRESHOLD,
                data[:refined],
                s
            )
        end
    end

end

end
end
end
end
end
end
