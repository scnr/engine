=begin
    Copyright 2020 Tasos Laskos <tasos.laskos@gmail.com> 

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'rack/test'
# require 'simplecov'
require 'faker'
require 'cuboid'

require_relative '../lib/scnr/engine'

# Enable for debugging.
require 'scnr/ui/cli'

require_relative 'support/helpers/paths'
require_relative 'support/helpers/requires'

Dir.glob( "#{support_path}/{lib,helpers,shared,factories}/**/*.rb" ).each { |f| require f }

# Uncomment to show output from spawned processes.
SCNR::Engine::Processes::Manager.preserve_output

RSpec::Core::MemoizedHelpers.module_eval do
    alias to should
    alias to_not should_not
end

RSpec.configure do |config|
    config.example_status_persistence_file_path = '.rspec_status'
    config.run_all_when_everything_filtered = true
    config.color = true
    config.add_formatter :documentation
    config.include PageHelpers
    config.alias_example_to :expect_it
    config.filter_run_when_matching focus: true

    config.mock_with :rspec do |mocks|
        mocks.yield_receiver_to_any_instance_implementation_blocks = true
    end

    config.before( :each ) do
        reset_all
    end

    config.after( :each ) do
        cleanup_instances
        processes_killall
    end
    config.after( :all ) do
        killall
    end
end
