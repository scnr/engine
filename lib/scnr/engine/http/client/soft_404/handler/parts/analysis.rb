=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine
module HTTP
class Client
class Soft404
class Handler
module Parts

module Analysis

    PRECISION = 2

    private

    def after_basic_analysis( url, &block )
        if analyzed?
            block.call
            return
        end

        generators = basic_probe_generators( url )

        hard_404s          = 0
        gathered_signatures = 0
        expected_signatures = generators.size

        generators.each.with_index do |generator, i|
            current_signature = (@basic_signatures[i] ||= {})

            signature_from_url generator.call, current_signature do |c_res|
                print_debug "[gathering]: #{self.url} #{c_res.request.url} #{c_res.url} #{c_res.code} #{block}"

                gathered_signatures += 1
                if c_res.code == 404
                    hard_404s += 1
                end

                next if gathered_signatures != expected_signatures

                print_status "Got basic signatures for: #{url}"

                # Base could behave like hard-404 but when given special
                # URLs behavior may change.
                if hard_404s == expected_signatures &&
                    !self.class.needs_advanced_analysis?( url )
                    hard!
                end

                analyzed!
                block.call
            end
        end
    end

    def after_advanced_analysis( url, &block )
        generators = advanced_probe_generators( url )

        if generators.empty?
            block.call
            return
        end

        gathered_signatures = 0
        expected_signatures = generators.size

        @advanced_signatures.clear
        generators.each.with_index do |generator, i|
            current_signature = (@advanced_signatures[i] ||= {})

            signature_from_url generator.call, current_signature do |c_res|
                print_debug "[gathering]: #{self.url} #{c_res.request.url} #{c_res.url} #{c_res.code} #{block}"

                gathered_signatures += 1
                next if gathered_signatures != expected_signatures

                print_status "Got advanced signature for: #{url}"
                block.call
            end
        end
    end

    # @return   [Array<Proc>]
    #   Generators for URLs which should elicit 404 responses for different types
    #   of scenarios.
    def basic_probe_generators( url)
        precision  = PRECISION
        uri        = SCNR::Engine::URI( url )
        up_to_path = uri.up_to_path

        trv_back = File.dirname( SCNR::Engine::URI( up_to_path ).path )
        trv_back << '/' if trv_back[-1] != '/'

        parsed = uri.dup
        parsed.path   = trv_back
        parsed.query  = ''
        trv_back_url  = self.url

        g = [
            # Get a random path with an extension.
            proc {
                s = up_to_path.dup
                s << random_string
                s << '.'
                s << random_string[0..precision]
                s
            },

            # Get a random path without an extension.
            proc { up_to_path + random_string },

            # Get a random path without an extension with all caps.
            #
            # Yes, this is here due to a real use case...
            proc { up_to_path + random_string_alpha_capital },

            # Move up a dir and get a random file.
            proc { trv_back_url + random_string },

            proc { trv_back_url + random_string_alpha_capital },

            # Move up a dir and get a random file with an extension.
            proc {
                s = trv_back_url.dup
                s << random_string
                s << '.'
                s << random_string[0..precision]
                s
            },

            # Get a random directory.
            proc {
                s = up_to_path.dup
                s << random_string
                s << '/'
                s
            }
        ]

        if !(rn = uri.resource_name.to_s).empty?
            # Append a random string to the resource name.
            g << proc { url.gsub( rn, "#{rn}#{random_string[0..precision]}" ) }

            g << proc { url.gsub( rn, "#{rn}-#{random_string[0..precision]}" ) }

            g << proc { url.gsub( rn, "#{rn}/#{random_string[0..precision]}" ) }

            g << proc do
                url.gsub( rn.split( '.', 2 ).first, "#{rn}(#{random_string[0..precision]}).#{parsed.resource_extension}" )
            end

            # Prepend a random string to the resource name.
            g << proc { url.gsub( rn, "#{random_string[0..precision]}#{rn}" ) }
        end

        g
    end

    # @return   [Array<Proc>]
    def advanced_probe_generators( url )
        precision  = PRECISION

        uri                = SCNR::Engine::URI( url )
        up_to_path         = uri.up_to_path
        resource_name      = uri.resource_name.to_s.split('.').tap(&:pop).join('.')
        resource_extension = uri.resource_extension

        probes = []

        if !resource_name.empty?
            # Get an existing resource with a random extension.
            probes << proc {
                s = up_to_path.dup
                s << resource_name
                s << '.'
                s << random_string[0..precision]
                s
            }
        end

        if resource_extension
            # Get a random filename with an existing extension.
            probes << proc {
                s = up_to_path.dup
                s << random_string
                s << '.'
                s << resource_extension
                s
            }
        end

        # Some webapps do routing based on name resources with "-" as a separator.
        if uri.resource_name.include?( '-' )
            rn = uri.resource_name

            probes << proc {
                up_to_path.sub( rn, rn.gsub( '-', "#{random_string}-" ) )
            }

            probes << proc {
                up_to_path.sub( rn, rn.gsub( '-', "-#{random_string}" ) )
            }
        end

        if uri.resource_name.include?( '~' )
            probes << proc {
                up_to_path.sub(
                    uri.resource_name,
                    resource_name.gsub( '~', '~~' )
                )
            }
        end

        probes
    end

    def random_string
        Digest::SHA1.hexdigest( rand( 9999999 ).to_s )
    end

    def random_string_alpha_capital
        s = random_string
        s.gsub!( /\d/, '' )
        s.upcase!
        s
    end

end

end
end
end
end
end
end
