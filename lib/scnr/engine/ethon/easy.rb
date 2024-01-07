=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module Ethon
class Easy

module Callbacks
    def debug_callback
        @debug_callback ||= proc do |handle, type, data, size, udata|
            # We only care about these so that we can have access to raw
            # HTTP request traffic for reporting/debugging purposes.
            next if type != :header_out && type != :data_out

            message = data.read_string( size )
            @debug_info.add type, message
            0
        end
    end
end

module Operations
    # Returns a pointer to the curl easy handle.
    #
    # @example Return the handle.
    #   easy.handle
    #
    # @return [ FFI::Pointer ] A pointer to the curl easy handle.
    def handle
        # Use proc for cleanup to avoid segfaults.
        @handle ||= FFI::AutoPointer.new(Curl.easy_init, proc { |pointer| Curl.easy_cleanup(pointer) })
    end

    # Sets a pointer to the curl easy handle.
    # @param [ ::FFI::Pointer ] Easy handle that will be assigned.
    def handle=(h)
        @handle = h
    end

    # Perform the easy request.
    #
    # @example Perform the request.
    #   easy.perform
    #
    # @return [ Integer ] The return code.
    def perform
        @return_code = Curl.easy_perform(handle)
        if Ethon.logger.debug?
            Ethon.logger.debug { "ETHON: performed #{log_inspect}" }
        end
        complete
        @return_code
    end

    # Clean up the easy.
    #
    # @example Perform clean up.
    #   easy.cleanup
    #
    # @return the result of the free which is nil
    def cleanup
        handle.free
    end

    # Prepare the easy. Options, headers and callbacks
    # were set.
    #
    # @example Prepare easy.
    #   easy.prepare
    #
    # @deprecated It is no longer necessary to call prepare.
    def prepare
        Ethon.logger.warn(
          "ETHON: It is no longer necessary to call "+
            "Easy#prepare. It's going to be removed "+
            "in future versions."
        )
    end
end

end
end
