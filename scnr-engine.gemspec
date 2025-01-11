# coding: utf-8
=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the Engine Framework project and is subject to
    redistribution and commercial restrictions. Please see the Engine Framework
    web site for more information on licensing and terms of use.
=end

Gem::Specification.new do |s|
    require_relative File.expand_path( File.dirname( __FILE__ ) ) + '/lib/scnr/engine/version'

    s.required_ruby_version = ['>= 2.4.0']

    s.name              = 'scnr-engine'
    s.version           = SCNR::Engine::VERSION
    s.date              = Time.now.strftime( '%Y-%m-%d' )
    s.summary           = 'SCNR::Engine is a feature-full, modular, high-performance' +
        ' Ruby framework aimed towards helping penetration testers and' +
        ' administrators evaluate the security of web applications.'

    s.homepage          = 'https://www.placeholder.com'
    s.email             = 'tasos.laskos@gmail.com'
    s.authors           = [ 'Tasos Laskos' ]
    s.licenses          = ['All rights reserved.']

    s.extensions       += %w(ext/Rakefile ext/engine/Cargo.toml ext/engine/Cargo.lock ext/engine/README.md)
    s.extensions       += Dir.glob( 'ext/engine/src/**/**' )

    s.files            += Dir.glob( 'bin/.gitkeep' )
    s.files            += Dir.glob( 'ext/engine/target/release/*.so' )
    s.files            += Dir.glob( 'config/**/**' )
    s.files            += Dir.glob( 'lib/**/**' )
    s.files            += Dir.glob( 'ui/**/**' )
    s.files            += Dir.glob( 'logs/**/**' )
    s.files            += Dir.glob( 'components/**/**' )
    s.files            += Dir.glob( 'profiles/**/**' )
    s.files            += %w(scnr-engine.gemspec)

    # Disable pushes to public servers.
    if s.respond_to?(:metadata)
        s.metadata['allowed_push_host'] = 'http://localhost/'
    else
        raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
    end

    s.extra_rdoc_files  = %w(README.md LICENSE.md CHANGELOG.md)

    s.rdoc_options      = [ '--charset=UTF-8' ]

    s.add_dependency 'scnr'
    s.add_dependency 'scnr-introspector',    '~> 0.1'

    s.add_dependency 'ruby-openai',          '~> 7.3.1'

    s.add_dependency 'cuboid',               '~> 0.2'
    s.add_dependency 'dsel'

    s.add_dependency 'webrick',              '1.9.1'

    # Rust extension helpers.
    s.add_dependency 'thermite',            '~> 0'

    # Don't specify version, messes with the packages since they always grab the
    # latest one.
    s.add_dependency 'bundler'

    # HTTP proxy server
    s.add_dependency 'http_parser.rb',      '0.8.0'

    # HTML report
    s.add_dependency 'coderay',             '1.1.3'

    # Optimized JSON.
    # s.add_dependency 'oj',                  '3.13.13'
    # s.add_dependency 'oj_mimic_json',       '1.0.1'

    # HTTP client.
    s.add_dependency 'typhoeus',            '~> 1.4.1'
    # s.add_dependency 'ethon',               '0.15.0'

    # Fallback URI parsing and encoding utilities.
    s.add_dependency 'addressable',         '2.8.7'

    # E-mail plugin.
    s.add_dependency 'pony',                '1.13.1'

    # Markup parsing, for reports and Element::XML.
    s.add_dependency 'nokogiri'
    # Really fast and lightweight markup parsing, for pages.
    s.add_dependency 'ox',                  '2.14.19'

    # Browser support for DOM/JS/AJAX analysis stuff.
    s.add_dependency 'watir',               '7.2.2'
    s.add_dependency 'selenium-webdriver',  '4.9.0'

    # Markdown to HTML conversion, used by the HTML report for component
    # descriptions.
    s.add_dependency 'redcarpet',            '3.6.0'
    s.add_dependency 'rouge',                '4.5.1'

    # Used to scrub Markdown for XSS etc.
    s.add_dependency 'loofah',              '2.24.0'

    s.add_development_dependency "rb_sys", "~> 0.9.39"
    s.add_development_dependency "rake-compiler", "~> 1.2"

    s.description = <<DESCRIPTION
SCNR::Engine is a feature-full, modular, high-performance Ruby framework aimed towards
helping penetration testers and administrators evaluate the security of web applications.

It is smart, it trains itself by monitoring and learning from the web application's
behavior during the scan process and is able to perform meta-analysis using a number of
factors in order to correctly assess the trustworthiness of results and intelligently
identify (or avoid) false-positives.

Unlike other scanners, it takes into account the dynamic nature of web applications,
can detect changes caused while travelling through the paths of a web application’s
cyclomatic complexity and is able to adjust itself accordingly. This way, attack/input
vectors that would otherwise be undetectable by non-humans can be handled seamlessly.

Moreover, due to its integrated browser environment, it can also audit and inspect
client-side code, as well as support highly complicated web applications which make
heavy use of technologies such as JavaScript, HTML5, DOM manipulation and AJAX.

Finally, it is versatile enough to cover a great deal of use cases, ranging from
a simple command line scanner utility, to RPC/REST distributed deployments, to a
grid of scanners and more.
DESCRIPTION

end
