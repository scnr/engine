=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

class SCNR::Engine::Plugins::WithOptions < SCNR::Engine::Plugin::Base
    def self.info
        {
            name:        'Component',
            description: %q{Component with options},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            options:     [
                Options::String.new(
                    'req_opt',
                    required:    true,
                    description: 'Required option'
                ),
                Options::String.new(
                    'opt_opt',
                    description: 'Optional option'
                ),
                Options::MultipleChoice.new(
                    'default_opt',
                    description: 'Option with default value',
                    default:     'value',
                    choices:     ['value', 'value2']
                )
            ]
        }
    end
end
