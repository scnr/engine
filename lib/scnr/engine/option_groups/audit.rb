=begin
    Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>

    This file is part of the SCNR::Engine project and is subject to
    redistribution and commercial restrictions. Please see the SCNR::Engine
    web site for more information on licensing and terms of use.
=end

module SCNR::Engine::OptionGroups

# Options for audit scope/coverage, mostly decides what types of elements
# should be considered.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Audit < SCNR::Engine::OptionGroup

    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Error

        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class InvalidLinkTemplate < Error
        end

        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class InvalidElementType < Error
        end
    end

    PARANOIA_LEVELS = %w(low medium high super)

    # @note Default is `true`.
    #
    # @return    [Bool]
    #   Inject payloads into parameter values.
    #
    # @see Element::Capabilities::Mutable#each_mutation
    attr_accessor :parameter_values

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Inject payloads into parameter names.
    #
    # @see Element::Capabilities::Mutable#each_mutation
    attr_accessor :parameter_names

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Allows checks to sent payloads in raw format, without HTTP encoding.
    #
    # @see Element::Capabilities::Mutable#each_mutation
    attr_accessor :with_raw_payloads

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Inject payloads into extra element parameters.
    #
    # @see Element::Capabilities::Mutable#each_mutation
    attr_accessor :with_extra_parameter

    # @note Default is `false`.
    #
    # @return   [Bool]
    #   If enabled, all element audits will be performed with both `GET` and
    #   `POST` HTTP methods.
    #
    # @see Element::Capabilities::Mutable::MUTATION_OPTIONS
    # @see Element::Capabilities::Mutable#each_mutation
    # @see Element::Capabilities::Mutable#switch_method
    attr_accessor :with_both_http_methods

    # @return    [Array<Regexp>]
    #   Patterns to use to exclude vectors from the audit, by name.
    #
    # @see Element::Capabilities::Auditable#audit
    attr_accessor :exclude_vector_patterns

    # @return    [Array<Regexp>]
    #   Patterns to use to include vectors in the audit exclusively, by name.
    #
    # @see Element::Capabilities::Auditable#audit
    attr_accessor :include_vector_patterns

    # @note Default is `:medium`.
    #
    # @return   [Symbol]
    #   `:low`. :medium`, :high`, :super`
    attr_accessor :paranoia

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Audit links.
    #
    # @see Element::Link
    # @see Element::Capabilities::Auditable#audit
    attr_accessor :links
    alias :link_doms  :links
    alias :link_doms= :links=

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Audit forms.
    #
    # @see Element::Form
    # @see Element::Capabilities::Auditable#audit
    attr_accessor :forms
    alias :form_doms  :forms
    alias :form_doms= :forms=

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Audit cookies.
    #
    # @see Element::Cookie
    # @see Element::Capabilities::Auditable#audit
    attr_accessor :cookies
    alias :cookie_doms  :cookies
    alias :cookie_doms= :cookies=

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Audit nested cookies.
    #
    # @see Element::NestedCookie
    # @see Element::Capabilities::Auditable#audit
    attr_accessor :nested_cookies

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Like {#cookies} but all cookie audits are submitted along with any other
    #   available element on the page.
    #
    # @see Element::Cookie#each_mutation
    # @see Element::Capabilities::Auditable#audit
    attr_accessor :cookies_extensively

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Audit HTTP request headers.
    attr_accessor :headers

    # @return   [Array<Regexp>]
    #   Regular expressions with named captures, serving as templates used to
    #   extract input vectors from links.
    #
    # @see Element::LinkTemplate
    attr_accessor :link_templates
    alias :link_template_doms  :link_templates
    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Audit HTTP request headers.
    attr_accessor :headers

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Audit JSON request inputs.
    attr_accessor :jsons

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Audit XML request inputs.
    attr_accessor :xmls

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Audit DOM inputs.
    attr_accessor :ui_inputs
    alias :ui_input_doms  :ui_inputs
    alias :ui_input_doms=  :ui_inputs=

    # @note Default is `false`.
    #
    # @return    [Bool]
    #   Audit DOM UI forms -- i.e. combination or orphan inputs and buttons.
    attr_accessor :ui_forms
    alias :ui_form_doms  :ui_forms
    alias :ui_form_doms=  :ui_forms=

    set_defaults(
        parameter_values:        true,
        paranoia:                :medium,
        exclude_vector_patterns: [],
        include_vector_patterns: [],
        link_templates:          []
    )

    PARANOIA_LEVELS.each do |level|
        define_method "#{level}_paranoia?" do
            self.paranoia == level.to_sym
        end
    end

    def paranoia=( level )
        return @paranoia = defaults[:paranoia] if !level

        if !PARANOIA_LEVELS.include? level.to_s
            fail ArgumentError, "Unknown paranoia level: #{level}"
        end

        @paranoia = level.to_sym
    end

    def with_raw_payloads?
        !!@with_raw_payloads
    end

    # @param    [Array<Regexp>] templates
    #   Regular expressions with named captures, serving as templates used to
    #   extract input vectors from paths.
    #
    # @raise    [Error::InvalidLinkTemplate]
    #
    # @see Element::LinkTemplate
    def link_templates=( templates )
        return @link_templates = [] if !templates

        @link_templates = [templates].flatten.compact.map do |s|
            template = s.is_a?( Regexp ) ?
                s :
                Regexp.new( s.to_s, Regexp::IGNORECASE )

            if template.names.empty?
                fail Error::InvalidLinkTemplate,
                     "Template '#{template}' includes no named captured."
            end

            template
        end
    end
    alias :link_template_doms= :link_templates=

    %w(include_vector_patterns exclude_vector_patterns).each do |m|
        define_method "#{m}=" do |patterns|
            patterns = [patterns].flatten.compact.
                map { |s| s.is_a?( Regexp ) ?
                s :
                Regexp.new( s.to_s, Regexp::IGNORECASE ) }

            instance_variable_set "@#{m}".to_sym, patterns
        end
    end

    # Enables auditing of element types.
    #
    # @param    [String, Symbol, Array] element_types
    #   Allowed:
    #
    #   * `:links`
    #   * `:forms`
    #   * `:cookies`
    #   * `:headers`
    def elements( *element_types )
        element_types.flatten.compact.each do |type|
            fail_on_unknown_element_type( type ) do
                self.send( "#{type}=", true ) rescue self.send( "#{type}s=", true )
            end
        end
        true
    end
    alias :elements= :elements
    alias :element   :elements
    alias :element=  :element

    # Disables auditing of element types.
    #
    # @param    [String, Symbol, Array] element_types
    #   Allowed:
    #
    #   * `:links`
    #   * `:forms`
    #   * `:cookies`
    #   * `:headers`
    def skip_elements( *element_types )
        element_types.flatten.compact.each do |type|
            fail_on_unknown_element_type( type ) do
                self.send( "#{type}=", false ) rescue self.send( "#{type}s=", false )
            end
        end
        true
    end
    alias :skip_element :skip_elements

    # Get audit settings for the given element types.
    #
    # @param    [String, Symbol, Array] element_types
    #   Allowed:
    #
    #   * `:links`
    #   * `:forms`
    #   * `:cookies`
    #   * `:headers`
    #   * `:ui_inputs`
    #   * `:ui_forms`
    #   * `:xmls`
    #   * `:jsons`
    #
    # @return   [Bool]
    #
    # @raise    [Error::InvalidLinkTemplate]
    def elements?( *element_types )
        !(element_types.flatten.compact.map do |type|
            fail_on_unknown_element_type( type ) do
                !!(self.send( "#{type}?" ) rescue self.send( "#{type}s?" ))
            end
        end.uniq.include?( false ))
    end
    alias :element? :elements?

    [:links, :forms, :cookies, :nested_cookies, :headers, :cookies_extensively,
     :with_both_http_methods, :link_doms, :form_doms, :cookie_doms,
     :jsons, :xmls, :ui_inputs, :ui_input_doms, :ui_forms, :ui_form_doms,
     :parameter_values, :parameter_names, :with_extra_parameter].each do |attribute|
        define_method "#{attribute}?" do
            !!send( attribute )
        end
    end

    def vector?( name )
        if include_vector_patterns.any? && !include_vector_patterns.find { |p| name.match? p }
            return false
        end

        !exclude_vector_patterns.find { |p| name.match? p }
    end

    # @return   [Bool]
    #   `true` if link templates have been specified, `false` otherwise.
    def link_templates?
        @link_templates.any?
    end
    alias :link_template_doms? :link_templates?

    def to_h
        h = super
        [:link_templates, :include_vector_patterns, :exclude_vector_patterns].each do |k|
            h[k] = h[k].map(&:source)
        end
        h
    end

    def to_rpc_data
        d = super
        d['paranoia'] = d['paranoia'].to_s
        d
    end

    private

    def fail_on_unknown_element_type( type, &block )
        begin
            block.call
        rescue NoMethodError
            fail Error::InvalidElementType, "Unknown element type: #{type}"
        end
    end

end
end
