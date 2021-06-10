=begin
    Copyright 2020 Alex Douckas <alexdouckas@gmail.com>, Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

Encoding.default_external = 'BINARY'
Encoding.default_internal = 'BINARY'

require 'rubygems'
require 'bundler/setup'
require 'tmpdir'
require 'cuboid'
require 'oj'
require 'oj_mimic_json'

require_relative 'engine/version'

# require 'bootsnap'
# Bootsnap.setup(
#     cache_dir:            "#{Dir.tmpdir}/scnr_engine_#{SCNR::Engine::VERSION}_code_cache",
#     load_path_cache:      true,  # Optimize the LOAD_PATH with a cache.
#     autoload_paths_cache: false, # Disable ActiveSupport cache.
#     compile_cache_iseq:   true,  # Compile Ruby code into ISeq cache, breaks coverage reporting.
#     compile_cache_yaml:   true   # Compile YAML into a cache.
# )

require 'concurrent'
require 'pp'
require 'ap'
require 'fiddle'

def ap( obj )
    super obj, raw: true
end

module SCNR
module Engine

    class <<self

        # Runs a minor GC to collect young, short-lived objects.
        #
        # Generally called after analysis operations that generate a lot of
        # new temporary objects.
        def collect_young_objects
            # GC.start( full_mark: false )
        end

        def null_device
            Gem.win_platform? ? 'NUL' : '/dev/null'
        end

        # @return   [Bool]
        def windows?
            Gem.win_platform?
        end

        # @return   [Bool]
        def linux?
            @is_linux ||= RbConfig::CONFIG['host_os'] =~ /linux/
        end

        # @return   [Bool]
        def mac?
            @is_mac ||= RbConfig::CONFIG['host_os'] =~ /darwin|mac os/i
        end

        # @return   [Bool]
        #   `true` if the `SCNR_ENGINE_PROFILE` env variable is set,
        #   `false` otherwise.
        def profile?
            !!ENV['SCNR_ENGINE_PROFILE']
        end

        def has_extension?
            @loaded_extension
        end

        def load_extension
            @loaded_extension = false

            if linux? || mac?
                ext_directory = File.dirname( File.dirname( __FILE__ ) ) + '/../ext'
                library_path  = "#{ext_directory}/engine/target/release/libscnr_engine."

                if linux?
                    library_path << 'so'
                elsif mac?
                    library_path << 'dylib'
                end

                if File.exists?( library_path )
                    Fiddle::Function.new(
                        Fiddle::dlopen( library_path )['initialize'],
                        [],
                        Fiddle::TYPE_VOIDP
                    ).call

                    @loaded_extension = true
                else
                    fail "Missing extension: #{library_path}"
                end
            end

            @loaded_extension
        end

        if Engine.windows?
            require 'find'
            require 'fileutils'
            require 'Win32API'
            require 'win32ole'

            def get_long_win32_filename( short_name )
                short_name = short_name.dup
                max_path   = 1024
                long_name  = ' ' * max_path

                lfn_size = Win32API.new(
                    "kernel32", 
                    "GetLongPathName",
                    ['P','P','L'],
                    'L'
                ).call( short_name, long_name, max_path )

                (1..max_path).include?( lfn_size ) ? 
                    long_name[0..lfn_size-1] : short_name
            end 
        else
            def get_long_win32_filename( short_name )
                short_name
            end
        end
    end

end
end

require_relative 'engine/banner'

SCNR::Engine::RPC       = Cuboid::RPC
SCNR::Engine::Processes = Cuboid::Processes

require_relative 'engine/ui/output_interface'

# If there's no UI driving us then there's no output interface.
# Chances are that someone is using Engine as a Ruby lib so there's no
# need for a functional output interface, so provide non-functional one.
#
# However, functional or not, the system does depend on one being available.
if !SCNR::Engine::UI.constants.include?(:Output)
    require_relative 'engine/ui/output'
end

SCNR::Engine.load_extension

require_relative 'engine/framework'
require_relative 'engine/ext/setup'

SCNR::Engine::UI::OutputInterface.initialize

