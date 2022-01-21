=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module HTTP
class ProxyServer

class SSLInterceptor < Connection
    include SCNR::Engine::UI::Output
    personalize_output!

    include TLS

    CA_PASSPHRASE  = 'interceptor'
    CA_CERTIFICATE = File.dirname( __FILE__ ) + '/ssl-interceptor-cacert.pem'
    CA_KEY         = File.dirname( __FILE__ ) + '/ssl-interceptor-cakey.pem'

    class <<self
        def ca
            @ca ||= OpenSSL::X509::Certificate.new( File.read( CA_CERTIFICATE ) )
        end

        def ca_key
            @ca_key ||= OpenSSL::PKey::RSA.new( File.read( CA_KEY ), CA_PASSPHRASE )
        end

        def keypair
            @keypair ||= OpenSSL::PKey::RSA.new( 2048 )
        end

        def certificate_for( host )
            synchronize { _certificate_for( host ) }
        end

        private

        def certificates
            @certificates ||= Support::Cache::LeastRecentlyUsed.new( size: 100 )
        end

        def _certificate_for( host )
            certificates[host] ||= begin
                req            = OpenSSL::X509::Request.new
                req.version    = 0
                req.subject    = OpenSSL::X509::Name.parse(
                    "CN=#{host}/subjectAltName=#{host}/O=SCNR::Engine/OU=Proxy/L=Athens/ST=Attika/C=GR"
                )
                req.public_key = keypair.public_key
                req.sign( keypair, OpenSSL::Digest::SHA512.new )

                cert            = OpenSSL::X509::Certificate.new
                cert.version    = 2
                cert.serial     = rand( 999999 )
                cert.not_before = Time.new
                cert.not_after  = cert.not_before + (60 * 60 * 24 * 365)
                cert.public_key = req.public_key
                cert.subject    = req.subject
                cert.issuer     = self.ca.subject

                ef = OpenSSL::X509::ExtensionFactory.new
                ef.subject_certificate = cert
                ef.issuer_certificate  = self.ca

                cert.extensions = [
                    ef.create_extension( 'basicConstraints', 'CA:FALSE', true ),
                    ef.create_extension( 'extendedKeyUsage', 'serverAuth', false ),
                    ef.create_extension( 'subjectKeyIdentifier', 'hash' ),
                    ef.create_extension( 'authorityKeyIdentifier', 'keyid:always,issuer:always' ),
                    ef.create_extension( 'keyUsage',
                                         'nonRepudiation,digitalSignature,keyEncipherment,dataEncipherment',
                                         true
                    )
                ]
                cert.sign( self.ca_key, OpenSSL::Digest::SHA512.new )
                cert
            end
        end

        def synchronize( &block )
            (@mutex ||= Mutex.new).synchronize( &block )
        end
    end
    synchronize{}
    certificates
    ca
    ca_key
    keypair

    def initialize( options )
        super

        @origin_host = options[:origin_host]
    end

    def on_connect
        print_debug_level_3 'Connected, starting SSL handshake.'

        start_tls(
          ca:          CA_CERTIFICATE,
          certificate: self.class.certificate_for( @origin_host ),
          key:         self.class.keypair
        )
    end

    def on_close( reason = nil )
        print_debug_level_3 "Closed because: [#{reason.class}] #{reason}"
        @parent.mark_connection_inactive self
    end

end

end
end
end
