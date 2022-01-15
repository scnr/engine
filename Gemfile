source 'https://rubygems.org'

# gem 'bootsnap', require: false
gem 'rake', '11.3.0'

gem 'nokogiri', github: 'sparklemotion/nokogiri'
gem 'ethon',    github: 'typhoeus/ethon', branch: 'thread-safe-easy-handle-cleanup'

gem 'cuboid',   github: 'qadron/cuboid'
gem 'dsel',     github: 'qadron/dsel'

group :docs do
    gem 'yard'
    gem 'redcarpet'
end

group :spec do
    gem 'simplecov', require: false, group: :test

    gem 'rspec'
    gem 'faker'

    if File.exist? '../ui-cli'
        gem 'scnr-ui-cli', path: '../ui-cli'
    end

    if File.exist? '../application'
        gem 'scnr-application', path: '../application'
    end
end

group :prof do

    gem 'benchmark-ips'
    gem 'memory_profiler'
end

gemspec
