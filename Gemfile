source 'https://rubygems.org'

# gem 'bootsnap', require: false

gem 'nokogiri', github: 'sparklemotion/nokogiri'

gem 'rake', '11.3.0'
gem 'cuboid', path: '../../../qadron/cuboid/'
gem 'dsel', path: '../../../qadron/dsel/'

gem 'arachni-reactor',      path: '../../../arachni-reactor'
gem 'ethon',      path: '../../../ethon'
# gem 'ethon', github: 'typhoeus/ethon', branch: 'thread-safe-easy-handle-cleanup'

# gem 'pry'

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
end

group :prof do

    # if File.exist? '../monitor'
    #     gem 'scnr-monitor', path: '../monitor'
    # end

    gem 'benchmark-ips'
    gem 'memory_profiler'
end

gemspec
