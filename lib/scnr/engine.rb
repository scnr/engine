=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

Encoding.default_external = 'BINARY'
Encoding.default_internal = 'UTF-8'

require 'rubygems'
require 'digest'

# require 'oj'
# require 'oj_mimic_json'

require 'bundler/setup'
require 'tmpdir'
require 'cuboid'

require_relative 'engine/version'
require_relative 'engine/support/crypto/rsa_aes_cbc'

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

if !defined?( RGLoader )
  module RGLoader
      def self.get_const( c )

          case c

          # Edition
          when 'e'
              -1

          # Duration (in days)
          when 'd'
              9999999
          end
      end
  end
end

def ap( obj )
    super obj, raw: true
end

module SCNR
module Engine

    EDITION_CODES = {
        -2 => :build,
        -1 => :development,
        0  => :trial,
        1  => :basic,
        2  => :pro,
        3  => :enterprise,
        4  => :reseller
    }

    ACTIVATION_FILE = File.dirname( __FILE__ ) + '/../../config/scnr.activation'
    FIRST_RUN_FILE = File.dirname( __FILE__ ) + '/../../config/scnr.fr'

    PRIVATE_KEY = "-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQDk6mpgfJ3O811Dfk19oe7YlVZ+MrLHCMNcTWulMne0Xg2DB9SC
Y/RhPIT+5Q/AFCntwcbEZ76rlyPHCoqOlQUqMngMih0hnUVAxUbKmXrCNEQRpPa+
2FDm7pGSPKadvGAGLpANOflA/zhyJvRbXCortpdPWCRc81klYKBHh5FxWwIDAQAB
AoGBAL6dpC7sFcw6QjLtfUFcEjMvR3KWbN/noCXAIh7RQ3RhzQaLAp4A9YHyjxxh
SRg8sh1U+lqZuN/RXu1jDbVkyYKij7nRzSDfaFia4vPBD3wgrDA2XNFw6wuFZdkv
2w5NJboiB5CGlY0kvA1GuCV+NpHU30+arFKUT2jFAHOjzmphAkEA8/x1s2H4MlVC
fNkjvXKKRQIGFuFEc96fLyG7b7gd3y7gkaSU3rnKW6sHbXnKFwYVyFvReA7z+Ox+
QsJoXI8mRwJBAPAv/IiaFjNe9vfulkWaYtQuBQNa9n2bXy6lV6pBFuCbX9uyZW6a
UitX5FdRCpHPqlINdfwsiltVCtiyNFZmok0CQHWBUgJZnZpIG6RbQ247GsKPbfVY
+om/XvTpDweIKcLSJc+e7x+xZPbvEL212RFrmdQL/H8Q3Ik3BLwMOwzQ2IMCQDYP
pvicLgkMA+yUMBCkikAVx50UuUxWT1sxbgTtN5gAgNfzVG9LntkQpF2e6REeu8hS
LU9AOzgJcTKLEcqsuTUCQE8Fcu28ShXNwZtas7JTWkP4AzPK5a+E4f0eekEX1IHf
R0UuXK923AqjI5zaG1VtCcb02Ql0CU1vmUVW3LMDV3M=
-----END RSA PRIVATE KEY-----
"

    PUBLIC_KEY = "-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDk6mpgfJ3O811Dfk19oe7YlVZ+
MrLHCMNcTWulMne0Xg2DB9SCY/RhPIT+5Q/AFCntwcbEZ76rlyPHCoqOlQUqMngM
ih0hnUVAxUbKmXrCNEQRpPa+2FDm7pGSPKadvGAGLpANOflA/zhyJvRbXCortpdP
WCRc81klYKBHh5FxWwIDAQAB
-----END PUBLIC KEY-----
"

    class <<self

        # Runs a minor GC to collect young, short-lived objects.
        #
        # Generally called after analysis operations that generate a lot of
        # new temporary objects.
        def collect_young_objects
            GC.start( full_mark: false )
        end

        def collect_objects
            GC.start
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

        def license_guard
            return if self.development?
            fail 'Cannot continue without valid activation.' unless File.exist?( ACTIVATION_FILE )
            fail 'Could not determine edition.' unless !!self.edition

            # self.prepare_activation_file
            # return

            self.load_activation_info rescue fail 'Corrupted activation file'

            activate! if !activated?

            if activated_on + license_duration <= Time.now
                fail 'License has expired.'
            end
        end

        def load_activation_info
            @activation_info ||= Marshal.load( crypto.decrypt( IO.binread( ACTIVATION_FILE ) ) )
        end

        def activate!
            info = {
              time: Time.now.to_i
            }

            IO.binwrite( ACTIVATION_FILE, crypto.encrypt( Marshal.dump( info ) ) )
        end

        def activated_on
            return if !activated?
            Time.at( @activation_info[:time] )
        end

        def first_run?
            @activation_info[:time].nil?
        end

        def activated?
            !!@activation_info[:time]
        end

        def crypto
            @crypto ||= Support::Crypto::RSA_AES_CBC.new( PUBLIC_KEY, PRIVATE_KEY )
        end

        def prepare_activation_file
            info = {
              time: nil
            }

            IO.binwrite( ACTIVATION_FILE, crypto.encrypt( Marshal.dump( info ) ) )
        end

        def license_duration
            d = RGLoader.get_const( 'd' )
            return if !d

            d.to_i
        end

        def license_file
            ENV['LICENSE_PATH']
        end

        def license_sha512
            Digest::SHA512.hexdigest IO.read( license_file )
        end

        def edition
            EDITION_CODES[edition_code]
        end

        EDITION_CODES.values.each do |e|
            define_method "#{e}?" do
                edition == e
            end
        end

        def edition_code
            e = RGLoader.get_const( 'e' )
            return if !e

            e.to_i
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

                if File.exist?( library_path )
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
require_relative 'engine/options'

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

SCNR::Engine::UI::OutputInterface.init
