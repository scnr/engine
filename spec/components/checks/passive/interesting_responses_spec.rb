require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Server ]
    end

    CODES = [
        102, 200, 201, 202, 203, 206, 207, 208, 226, 300, 301, 302,
        303, 305, 306, 307, 308, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409,
        410, 411, 412, 413, 414, 415, 416, 417, 418, 420, 422, 423, 424, 425, 426, 428,
        429, 431, 444, 449, 450, 451, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508,
        509, 510, 511, 598, 599
    ]

    it 'logs HTTP responses with status codes other than 200 or 404' do
        run
        CODES.each do |code|
            http.get( url + code.to_s )
        end
        CODES.each do |code|
            http.get( url + 'blah/' + code.to_s )
        end
        http.run

        max_issues = current_check.max_issues
        expect(issues.size).to eq(max_issues)
    end

    it 'skips HTTP responses which are out of scope' do
        options.scope.exclude_path_patterns << /blah/

        run

        CODES.each do |code|
            http.get( url + 'blah/' + code.to_s )
        end
        http.run

        expect(issues).to be_empty
    end
end
