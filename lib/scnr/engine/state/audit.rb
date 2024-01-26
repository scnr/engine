=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'forwardable'

module SCNR::Engine
class State

# Stores and provides access to the state of all audit operations performed by:
#
#   * {Check::Auditor}
#       * {Check::Auditor.audited}
#       * {Check::Auditor#audited}
#       * {Check::Auditor#audited?}
#   * {Element::Capabilities::Auditable}
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Audit
    extend ::Forwardable

    def initialize
        @collection = Support::Filter::Set.new( hasher: :persistent_hash )
    end

    def statistics
        {
            total: size
        }
    end

    [:<<, :merge, :include?, :clear, :empty?, :any?, :size, :hash, :==].each do |method|
        def_delegator :collection, method
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        IO.binwrite( "#{directory}/set", Marshal.dump( self ) )
    end

    def self.load( directory )
        Marshal.load( IO.binread( "#{directory}/set" ) )
    end

    private

    def collection
        @collection
    end

end

end
end
