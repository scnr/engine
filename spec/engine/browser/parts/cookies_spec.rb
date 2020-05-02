require 'spec_helper'

describe SCNR::Engine::Browser::Parts::Cookies do
    include_examples 'browser'

    describe '#cookies' do
        it 'returns cookies visible via JavaScript' do
            subject.load url

            cookie = subject.cookies.find { |c| c.name == 'cookie_name' }

            expect(cookie.name).to  eq 'cookie_name'
            expect(cookie.value).to eq 'cookie value'
            expect(cookie.raw_name).to  eq 'cookie_name'
            expect(cookie.raw_value).to eq '"cookie value"'
        end

        it 'preserves expiration value' do
            subject.load "#{url}/cookies/expires"

            cookie = subject.cookies.first
            expect(cookie.name).to  eq 'without_expiration'
            expect(cookie.value).to eq 'stuff'
            expect(cookie.expires).to be_nil

            cookie = subject.cookies.last
            expect(cookie.name).to  eq 'with_expiration'
            expect(cookie.value).to eq 'bar'
            expect(cookie.expires.to_s).to eq Time.parse( '2047-08-01 09:30:11 +0000' ).to_s
        end

        # Need a better test, Chrome returns no cookies for '.localhost'
        # (or is it a bug and it's all subdomains?) and Firefox just converts
        # '.localhost' to 'localhost', is this only for localhost or general bug?
        it 'preserves the domain' do
            skip

            subject.load "#{url}/cookies/domains"

            cookies = subject.cookies

            cookie = cookies.find { |c| c.name == 'include_subdomains' }
            expect(cookie.name).to  eq 'include_subdomains'
            expect(cookie.value).to eq 'bar1'
            expect(cookie.domain).to eq ".#{SCNR::Engine::URI( url ).host}"
        end

        it 'ignores cookies for other domains' do
            subject.load "#{url}/cookies/domains"

            cookies = subject.cookies
            expect(cookies.find { |c| c.name == 'other_domain' }).to be_nil
        end

        it 'preserves the path' do
            subject.load "#{url}/cookies/under/path"

            cookie = subject.cookies.first
            expect(cookie.name).to  eq 'cookie_under_path'
            expect(cookie.value).to eq 'value'
            expect(cookie.path).to eq '/cookies/under'
        end

        it 'preserves httpOnly' do
            subject.load "#{url}/cookies/under/path"

            cookie = subject.cookies.first
            expect(cookie.name).to  eq 'cookie_under_path'
            expect(cookie.value).to eq 'value'
            expect(cookie.path).to eq '/cookies/under'
            expect(cookie).to_not be_http_only

            subject.load "#{url}/cookies/httpOnly"

            cookie = subject.cookies.first
            expect(cookie.name).to  eq 'http_only'
            expect(cookie.value).to eq 'stuff'
            expect(cookie).to be_http_only
        end

        context 'when parsing v1 cookies' do
            it 'removes the quotes' do
                cookie = 'rsession="06142010_0%3Ae275d357943e9a2de0"'

                subject.load url
                subject.javascript.run( "document.cookie = '#{cookie}';" )

                cookie = subject.cookies.find { |c| c.name == 'rsession' }
                expect(cookie.value).to eq('06142010_0:e275d357943e9a2de0')
                expect(cookie.raw_value).to eq('"06142010_0%3Ae275d357943e9a2de0"')
            end
        end

        context 'when no page is available' do
            it 'returns an empty Array' do
                expect(subject.cookies).to be_empty
            end
        end
    end

end
