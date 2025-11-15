require 'spec_helper'

describe SCNR::Engine::Parser::OpenAPI do
    before :each do
        SCNR::Engine::Options.url = url
        SCNR::Engine::Options.audit.elements :links, :forms
        SCNR::Engine::Options.audit.link_templates = /id\/(?<id>\w+)/
    end
    let(:url) { 'http://example.com' }
    let(:valid_openapi_schema) do
        {
          'openapi' => '3.0.0',
          'paths' => {
            '/example' => {
              'get' => {}
            }
          }
        }
    end
    let(:valid_openapi_schema_with_servers) do
        {
          'openapi' => '3.0.0',
          'servers' => [
            { 'url' => 'https://example.com/v1' },
            { 'url' => 'https://example.com/v2' }
          ],
          'paths' => {
            '/example' => {
              'get' => {}
            }
          }
        }
    end
    let(:response) do
        SCNR::Engine::HTTP::Response.new(
          url: url,
          code: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: valid_openapi_schema.to_json
        )
    end

    let(:invalid_openapi_schema) { { 'paths' => {} } }
    let(:valid_openapi_json) { valid_openapi_schema.to_json }
    let(:valid_openapi_yaml) { valid_openapi_schema.to_yaml }
    let(:invalid_openapi_json) { invalid_openapi_schema.to_json }
    let(:invalid_openapi_yaml) { invalid_openapi_schema.to_yaml }

    describe '.openapi?' do
        it 'returns true for valid OpenAPI JSON content' do
            expect(described_class.openapi?(valid_openapi_json)).to be true
        end

        it 'returns true for valid OpenAPI YAML content' do
            expect(described_class.openapi?(valid_openapi_yaml)).to be true
        end

        it 'returns false for invalid OpenAPI JSON content' do
            expect(described_class.openapi?(invalid_openapi_json)).to be false
        end

        it 'returns false for invalid OpenAPI YAML content' do
            expect(described_class.openapi?(invalid_openapi_yaml)).to be false
        end

        it 'returns false for non-OpenAPI content' do
            expect(described_class.openapi?('random string')).to be false
        end
    end

    describe '.parse' do
        it 'parses valid OpenAPI JSON content and returns an OpenAPI instance' do
            result = described_class.parse(valid_openapi_json)
            expect(result).to be_a(described_class)
        end

        it 'parses valid OpenAPI YAML content and returns an OpenAPI instance' do
            result = described_class.parse(valid_openapi_yaml)
            expect(result).to be_a(described_class)
        end

        it 'raises an error for invalid OpenAPI content' do
            expect { described_class.parse(invalid_openapi_json) }.to raise_error(
                                                                        SCNR::Engine::Parser::OpenAPI::InvalidOpenAPISchemaError,
                                                                        'Not OpenAPI schema!'
                                                                      )
        end

        it 'raises an error for non-parsable content' do
            expect { described_class.parse('random string') }.to raise_error(
                                                                   SCNR::Engine::Parser::OpenAPI::InvalidOpenAPISchemaError,
                                                                   'Not OpenAPI schema!'
                                                                 )
        end
    end

    describe '#response' do
        it 'parses a response' do
            openapi = described_class.new(response)

            links = openapi.links

            expect(links.size).to eq(1)
            expect(links.first.url).to eq(url + '/example')
            expect(links.first.method).to eq(:get)
        end
    end

    describe '#page' do
        it 'returns a Page instance with the correct parser' do
            openapi = described_class.new(response)
            page = openapi.page

            expect(page).to be_a(SCNR::Engine::Page)
            expect(page.parser).to eq(openapi)
        end
    end

    describe '#paths' do
        it 'returns the paths from the schema' do
            openapi = described_class.new(valid_openapi_schema, url)
            expect(openapi.paths).to eq(['/example'])
        end
    end

    describe '#links' do
        it 'returns links for GET methods without path parameters' do
            schema = {
              'openapi' => '3.0.0',
              'paths' => {
                '/example' => { 'get' => {} },
                '/example/{id}' => { 'get' => {} }
              }
            }
            openapi = described_class.new(schema, url)
            links = openapi.links

            expect(links.size).to eq(1)
            expect(links.first.url).to eq(url + '/example')
            expect(links.first.method).to eq(:get)
        end
    end

    describe '#link_templates' do
        it 'returns link templates for GET methods with path parameters' do
            schema = {
              'openapi' => '3.0.0',
              'paths' => {
                '/example/{id}' => { 'get' => {} }
              }
            }
            openapi = described_class.new(schema, url)
            templates = openapi.link_templates

            expect(templates.size).to eq(1)
            expect(templates.first.url).to eq(url + '/example/%7Bid%7D')
            expect(templates.first.inputs).to eq( { 'id' => '{id}'})
            expect(templates.first.template).to eq(/\/example\/(?<id>[^\/]+)/)
        end
    end

    describe '#forms' do
        it 'returns forms for paths with request bodies' do
            schema = {
              'openapi' => '3.0.0',
              'paths' => {
                '/example' => {
                  'post' => {
                    'requestBody' => {
                      'content' => {
                        'application/json' => {
                          'schema' => {
                            'properties' => {
                              'name' => { 'type' => 'string' }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            openapi = described_class.new(schema, url)
            forms = openapi.forms

            expect(forms.size).to eq(1)
            expect(forms.first.url).to eq(url + '/example')
            expect(forms.first.action).to eq(url + '/example')
            expect(forms.first.inputs).to eq({ 'name' => '' })
        end
    end
end
