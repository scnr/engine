module SCNR::Engine

class Parser
class OpenAPI

    class InvalidOpenAPISchemaError < StandardError; end

    class<<self

        def openapi?( candidate )
            parsed = parse_content( candidate )
            parsed.is_a?(Hash) && (parsed.key?('openapi') || parsed.key?('swagger'))
        end

        def parse( schema, base_url = nil )
            raise InvalidOpenAPISchemaError, "Not OpenAPI schema!" unless openapi?(schema)

            parsed = parse_content(schema)
            OpenAPI.new(parsed, base_url) if parsed
        end

        def parse_content(content)
            return content if content.is_a?(Hash)

            begin
                ::YAML.safe_load(content)
            rescue => e
                begin
                    ::JSON.parse(content)
                rescue => e
                    nil
                end
            end

        end
    end

    attr_accessor :url
    attr_accessor :response

    def initialize( resource, url = nil )
        @url = url

        case resource

            when Hash
                @resource = :document
                @schema = resource

                fail InvalidOpenAPISchemaError unless self.class.openapi? ( @schema )

            when HTTP::Response
                @resource = :response

                @response = resource
                @schema = self.class.parse_content( resource.body )

                fail InvalidOpenAPISchemaError unless self.class.openapi? ( @schema )

                self.url = @response.url
        end
    end

    def cookies
        []
    end

    def cookies_to_be_audited
        []
    end

    # @return   [Array<Element::Cookie>]
    #   Cookies with which to update the HTTP cookie-jar.
    def cookie_jar
        return @cookie_jar.freeze if @cookie_jar
        from_jar = []

        # Make a list of the response cookie names.
        cookie_names = Set.new( cookies.map( &:name ) )

        from_jar |= HTTP::Client.cookie_jar.for_url( @url ).
          reject { |cookie| cookie_names.include?( cookie.name ) }

        @cookie_jar = (cookies | from_jar)
    end


    def page
        @page ||= Page.new( parser: self )
    end

    def paths
        @schema['paths'].keys
    end

    def body
        @schema.to_yaml
    end

    def links
        @schema['paths'].each_with_object([]) do |(path, methods), result|
            methods.each_key do |method, _details|
                next unless method.downcase == 'get'
                next if path.include?('{') && path.include?('}')

                link = SCNR::Engine::Element::Link.new(
                  url: url_to_absolute( path ),
                  method: method.downcase.to_sym
                )
                next if link.scope.out?

                result << link
            end
        end
    end

    def link_templates
        @schema['paths'].each_with_object([]) do |(path, methods), result|
            methods.each_key do |method, _details|
                next unless method.downcase == 'get'
                next unless path.include?('{') && path.include?('}')

                parameter_names = path.scan(/{([^}]+)}/).flatten
                template = Regexp.new(path.gsub(/{([^}]+)}/, '(?<\1>[^/]+)'))

                linkt = SCNR::Engine::Element::LinkTemplate.new(
                  url: url_to_absolute( path ),
                  method: method.upcase,
                  template: template,
                  parameters: parameter_names
                )
                next if linkt.scope.out?

                result << linkt
            end
        end
    end

    def forms
        @schema['paths'].each_with_object([]) do |(path, methods), result|
            methods.each do |method, details|
                next unless details['requestBody']

                form = SCNR::Engine::Element::Form.new(
                  url: url_to_absolute( path ),
                  method: method.downcase.to_sym,
                  inputs: extract_inputs( details['requestBody'] )
                )
                next if form.scope.out?

                result << form
            end
        end
    end

    def jsons
        []
    end

    def xmls
        []
    end

    private

    def url_to_absolute( path )
        URI.to_absolute( path, @url )
    end

    def extract_inputs(request_body)
        schema = request_body.dig('content', 'application/json', 'schema')
        return {} unless schema && schema['properties']

        schema['properties'].each_with_object({}) do |(name, _details), inputs|
            inputs[name] = nil # Default value for each input
        end
    end

end
end
end
