=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Checks::Test < SCNR::Engine::Check::Base

    def prepare
        @prepared = true
    end

    def run
        return if !@prepared
        @ran = true

        SCNR::Engine::HTTP::Client.get( "http://localhost/#{shortname}" ){}
    end

    def clean_up
        return if !@ran
        log( page: page, vector: vector )
    end

    def vector
        v = SCNR::Engine::Element::Link.new( url: 'http://test.com', inputs: { stuff: 1 } )
        v.affected_input_name  = rand(9999).to_s + rand(9999).to_s
        v.affected_input_value = 2
        v.seed                 = 2
        v
    end

    def self.info
        {
            name:        'Test check',
            description: %q{Test description},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1',

            issue:       {
                name:            %q{Test issue},
                description:     %q{Test description},
                references:  {
                    'Wikipedia' => 'http://en.wikipedia.org/'
                },
                tags:            ['some', 'tag'],
                cwe:             '0',
                severity:        Severity::HIGH,
                remedy_guidance: %q{Watch out!.},
                remedy_code:     ''
            }

        }
    end

end
