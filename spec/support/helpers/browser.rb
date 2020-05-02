def browser_explore_check_pages( pages )
    pages_should_have_form_with_input pages, 'by-ajax'
    pages_should_have_form_with_input pages, 'from-post-ajax'
    pages_should_have_form_with_input pages, 'ajax-token'
    pages_should_have_form_with_input pages, 'href-post-name'
end

module ProcToMethod

    def proc_to_method=( p )
        @p = p
    end

    def proc_to_method( *args )
        @p.call *args
    end

    extend self
end

def proc_to_method( &block )
    ProcToMethod.proc_to_method = block
    ProcToMethod.method(:proc_to_method)
end

def format_js!( js )
    js.gsub!( ' ', '' )
    js
end

def format_js_elements_with_events!( ewe )
    ewe.each do |e|
        e['events'].each do |_, handlers|
            handlers.each do |h|
                format_js!( h )
            end
        end
    end
    ewe
end
