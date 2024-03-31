=begin
    Copyright 2024 Ecsypno Single Member P.C.

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

require 'yaml'
require 'singleton'

require_relative 'error'
require_relative 'utilities'

module SCNR::Engine

# Provides access to all of {Engine}'s runtime options.
#
# To make management of options for different subsystems easier, some options
# are {OptionGroups grouped together}.
#
# {OptionGroups Option groups} are initialized and added as attribute readers
# to this class dynamically. Their attribute readers are named after the group's
# filename and can be accessed, like so:
#
#     Engine::Options.scope.page_limit = 10
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @see OptionGroups
class Options
    include Singleton

    def self.attr_accessor(*vars)
        @attr_accessors ||= []
        @attr_accessors |= vars
        super( *vars )
    end

    def self.attr_accessors
        @attr_accessors
    end

    def attr_accessors
        self.class.attr_accessors
    end

    # {Options} error namespace.
    #
    # All {Options} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < SCNR::Engine::Error

        # Raised when a provided {Options#url= URL} is invalid.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class InvalidURL < Error
        end

        # Raised when a provided 'localhost' or '127.0.0.1' {Options#url= URL}.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class ReservedHostname < Error
        end
    end

    class <<self

        def method_missing( sym, *args, &block )
            if instance.respond_to?( sym )
                instance.send( sym, *args, &block )
            else
                super( sym, *args, &block )
            end
        end

        def respond_to?( *args )
            super || instance.respond_to?( *args )
        end

        # Ruby 2.0 doesn't like my class-level method_missing for some reason.
        # @private
        public :allocate

        # @return   [Hash<Symbol,OptionGroup>]
        #   {OptionGroups Option group} classes by name.
        def group_classes
            @group_classes ||= {}
        end

        # Should be called by {OptionGroup.inherited}.
        # @private
        def register_group( group )
            name = Utilities.caller_name

            # Prepare an attribute reader for this group...
            attr_reader name

            # ... and initialize it.
            instance_variable_set "@#{name}".to_sym, group.new

            group_classes[name.to_sym] = group
        end
    end

    # Load all {OptionGroups}.
    require_relative 'option_groups'

    TO_RPC_IGNORE = Set.new([
        :parsed_url, :instance, :rpc, :dispatcher, :queue, :paths,
        :snapshot, :report, :output, :system,
    ])

    TO_HASH_IGNORE = Set.new([ :parsed_url, :instance ])

    # @return    [String]
    #   The URL to audit.
    attr_reader   :url

    # @return    [SCNR::Engine::URI]
    attr_reader   :parsed_url

    # @return    [Array<String, Symbol>]
    #   Checks to load, by name.
    #
    # @see Checks
    # @see Check::Base
    # @see Check::Manager
    attr_accessor :checks

    attr_accessor :check_server

    # @return   [Array<Symbol>]
    #   Platforms to use instead of (or in addition to, depending on the
    #   {#no_fingerprinting option}) fingerprinting.
    #
    # @see Platform
    # @see Platform::List
    # @see Platform::Manager
    attr_accessor :platforms

    # @return   [Hash{<String, Symbol> => Hash{String => String}}]
    #   Plugins to load, by name, as keys and their options as values.
    #
    # @see Plugins
    # @see Plugin::Base
    # @see Plugin::Manager
    attr_accessor :plugins

    # @return    [String]
    #   E-mail address of the person that authorized the scan. It will be added
    #   to the HTTP `From` headers.
    #
    # @see HTTP::Client#headers
    attr_accessor :authorized_by

    # @return   [Bool]
    #   Disable platform fingeprinting.
    #
    # @see Platform::Fingerprinter
    # @see Platform::Fingerprinters
    # @see Platform::List
    # @see Platform::Manager
    attr_accessor :no_fingerprinting

    def initialize
        reset
    end

    # Restores everything to their default values.
    #
    # @return [Options] `self`
    def reset
        # nil everything out.
        instance_variables.each { |var| instance_variable_set( var.to_s, nil ) }

        # Set fresh option groups.
        group_classes.each do |name, klass|
            instance_variable_set "@#{name}".to_sym, klass.new
        end

        @checks    = []
        @platforms = []
        @plugins   = {}

        @no_fingerprinting = false
        @authorized_by     = nil

        @check_server = ENV['SCNR_CHECK_SERVER'] || "https://checks.ecsypno.com"

        self
    end

    # Disables platform fingerprinting.
    def do_not_fingerprint
        self.no_fingerprinting = true
    end

    # Enables platform fingerprinting.
    def fingerprint
        self.no_fingerprinting = false
    end

    # @return   [Bool]
    #   `true` if platform fingerprinting is enabled, `false` otherwise.
    def fingerprint?
        !@no_fingerprinting
    end

    # Normalizes and sets `url` as the target URL.
    #
    # @param    [String]    url
    #   Absolute URL of the targeted web app.
    #
    # @return   [String]
    #   Normalized `url`
    #
    # @raise    [Error::InvalidURL]
    #   If the given `url` is not valid.
    def url=( url )
        return @url = nil if !url

        parsed = SCNR::Engine::URI( url.to_s )

        if parsed.to_s.empty? || !parsed.absolute?

            fail Error::InvalidURL,
                 'Invalid URL argument, please provide a full absolute URL and try again.'

        else

            if scope.https_only? && parsed.scheme != 'https'

                fail Error::InvalidURL,
                     "Invalid URL argument, the 'https-only' option requires"+
                         ' an HTTPS URL.'

            elsif !%w(http https).include?( parsed.scheme )

                fail Error::InvalidURL,
                     'Invalid URL scheme, please provide an HTTP or HTTPS URL and try again.'

            end

        end

        @parsed_url = parsed
        @url        = parsed.to_s
    end

    # Configures options via a Hash object.
    #
    # @example Configuring direct and {OptionGroups} attributes.
    #
    #     {
    #         # Direct Options#url attribute.
    #         url:    'http://test.com/',
    #         # Options#audit attribute pointing to an OptionGroups::Audit instance.
    #         audit:  {
    #             # Works due to the OptionGroups::Audit#elements= helper method.
    #             elements: [ :links, :forms, :cookies ]
    #         },
    #         # Direct Options#checks attribute.
    #         checks: [ :xss, 'sql_injection*' ],
    #         # Options#scope attribute pointing to an OptionGroups::Scope instance.
    #         scope:  {
    #             # OptionGroups::Scope#page_limit
    #             page_limit:            10,
    #             # OptionGroups::Scope#directory_depth_limit
    #             directory_depth_limit: 3
    #         },
    #         # Options#http attribute pointing to an OptionGroups::HTTP instance.
    #         http:  {
    #             # OptionGroups::HTTP#request_concurrency
    #             request_concurrency: 25,
    #             # OptionGroups::HTTP#request_timeout
    #             request_timeout:     10_000
    #         }
    #     }
    #
    # @param    [Hash]  options
    #   If the key refers to a class attribute, the attribute will be assigned
    #   the given value, if it refers to one of the {OptionGroups} the value
    #   should be a hash with data to update that {OptionGroup group} using
    #   {OptionGroup#update}.
    #
    # @return   [Options]
    #
    # @see OptionGroups
    def update( options )
        options.each do |k, v|
            k = k.to_sym
            if group_classes.include? k
                send( k ).update v
            else
                send( "#{k.to_s}=", v )
            end
        end

        self
    end
    alias :set :update

    # @return   [Hash]
    #   Hash of errors with the name of the invalid options/groups as the keys.
    def validate
        errors = {}
        group_classes.keys.each do |name|
            next if (group_errors = send(name).validate).empty?
            errors[name] = group_errors
        end
        errors
    end

    # @param    [String]    file
    #   Saves `self` to `file` using YAML.
    def save( file )
        File.open( file, 'w' ) do |f|
            f.write to_save_data
            f.path
        end
    end

    def to_save_data
        to_rpc_data.to_yaml
    end

    def to_save_data_without_defaults
        to_rpc_data_without_defaults.to_yaml
    end

    # Loads a file created by {#save}.
    #
    # @param    [String]    filepath
    #   Path to the file created by {#save}.
    #
    # @return   [SCNR::Engine::Options]
    def load( filepath )
        update( YAML.load_file( filepath ) )
    end

    # @return    [Hash]
    #   `self` converted to a Hash suitable for RPC transmission.
    def to_rpc_data
        hash = {}
        instance_variables.each do |var|
            val = instance_variable_get( var )
            var = normalize_name( var )

            next if TO_RPC_IGNORE.include?( var )

            hash[var.to_s] = (val.is_a? OptionGroup) ? val.to_rpc_data : val
        end
        hash.deep_clone
    end

    def to_rpc_data_without_defaults
        defaults = self.class.allocate.reset.to_rpc_data
        to_rpc_data.reject { |k, v| defaults[k] == v }
    end

    # @return    [Hash]
    #   `self` converted to a Hash.
    def to_hash
        hash = {}
        instance_variables.each do |var|
            val = instance_variable_get( var )
            var = normalize_name( var )

            next if TO_HASH_IGNORE.include?( var )

            hash[var] = (val.is_a? OptionGroup) ? val.to_h : val
        end

        hash.deep_clone
    end
    alias :to_h :to_hash

    # @param    [Hash]  hash
    #   Hash to convert into {#to_hash} format.
    #
    # @return   [Hash]
    #   `hash` in {#to_hash} format.
    def rpc_data_to_hash( hash )
        self.class.allocate.reset.update( hash ).to_hash.
            reject { |k| TO_RPC_IGNORE.include? k }
    end

    # @param    [Hash]  hash
    #   Hash to convert into {#to_rpc_data} format.
    #
    # @return   [Hash]
    #   `hash` in {#to_rpc_data} format.
    def hash_to_rpc_data( hash )
        self.class.allocate.reset.update( hash ).to_rpc_data
    end

    def hash_to_save_data( hash )
        self.class.allocate.reset.update( hash ).to_save_data
    end

    def dup
        self.class.allocate.reset.update( self.to_h )
    end

    private

    def group_classes
        self.class.group_classes
    end

    def normalize_name( name )
        name.to_s.gsub( '@', '' ).to_sym
    end

end
end
