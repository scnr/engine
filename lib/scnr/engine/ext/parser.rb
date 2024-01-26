=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
class Parser

    if SCNR::Engine.has_extension?
        module Ext
        end

        PROVIDER = Ext
    else
        module Ruby
        end

        PROVIDER = Ruby
    end

    dir = PROVIDER.to_s.split( '::' ).last.downcase
    [
        'nodes/base',
        'nodes/comment',
        'nodes/element',
        'nodes/text',
        'document',
    ].each do |file|
        require_relative "../parser/#{dir}/#{file}"
    end

    Nodes    = PROVIDER::Nodes
    Document = PROVIDER::Document

end
end
