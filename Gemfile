source 'https://rubygems.org'

# gem 'bootsnap', require: false
gem 'rake', '11.3.0'

gem 'ethon', github: 'typhoeus/ethon', branch: 'thread-safe-easy-handle-cleanup'

group :docs do
    gem 'yard'
    gem 'redcarpet'
end

group :spec do
    gem 'simplecov', require: false, group: :test

    gem 'thin'
    gem 'sinatra'
    gem 'sinatra-contrib'

    gem 'rspec', '3.11.0'
    gem 'faker'

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

gemspec
