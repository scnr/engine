source 'https://rubygems.org'

# gem 'bootsnap', require: false
gem 'rake', '>= 12.3.3'

# gem 'ethon', github: 'typhoeus/ethon', branch: 'thread-safe-easy-handle-cleanup'

group :docs do
    gem 'yard'
    gem 'redcarpet'
end

group :spec do
    gem 'simplecov', require: false, group: :test

    gem 'rackup'
    gem 'puma', '5.6.9'

    # DO NOT TOUCH THIS GROUP VERSION
    gem 'rack', '2.2.4'
    gem 'sinatra', '3.2.0'
    gem 'sinatra-contrib', '3.2.0'

    gem 'rspec', '3.11.0'
    gem 'faker'

    if File.exist? '../scnr'
        gem 'scnr', path: '../scnr'
    end

    if File.exist? '../introspector'
        gem 'scnr-introspector', path: '../introspector'
    end

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

gem 'scnr', path: '../scnr'
# gem 'cuboid', path: '../../qadron/cuboid'
# gem 'raktr', path: '../../qadron/raktr'
# gem 'toq', path: '../../qadron/toq'

gemspec
