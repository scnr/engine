=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

# Looks for HTML "object" tags.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class SCNR::Engine::Checks::HtmlObjects < SCNR::Engine::Check::Base

    def self.regexp
        @regexp ||= /<object.*?>.*?<\/object>/im
    end

    def run
        match_and_log( self.class.regexp ) { |m| m && !m.empty? }
    end

    def self.info
        description = %q{Logs the existence of HTML object tags.
                Since SCNR::Engine can't execute things like Java Applets and Flash
                this serves as a heads-up to the penetration tester to review
                the objects in question using a different method.}
        {
            name:        'HTML objects',
            description: description,
            elements:    [ Element::Body ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',

            issue:       {
                name:        %q{HTML object},
                cwe:         200,
                description: description,
                severity:    Severity::INFORMATIONAL
            },
            max_issues: 25
        }
    end

end
