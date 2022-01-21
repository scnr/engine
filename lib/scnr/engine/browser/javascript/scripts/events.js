/*
 * Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>
 *
 * This file is part of the SCNR::Engine project and is subject to
 * redistribution and commercial restrictions. Please see the SCNR::Engine
 * web site for more information on licensing and terms of use.
 */

/*
 */
var _tokenEvents = {

    input_events: {
        'change':   true,
        'blur':     true,
        'focus':    true,
        'select':   true,
        'keyup':    true,
        'keypress': true,
        'keydown':  true,
        'input':    true
    },

    fire: function ( tag_name, css, event, options ) {
        var element = document.querySelector( css );

        if( !_tokenDOMMonitor.is_visible( element ) ) return false;

        if( tag_name == 'form' ) {
            _tokenEvents.fill_in_form_inputs( element, options.inputs );

            if( event == 'submit' ) {
                var submit_btn = element.querySelector(
                    "input[type='submit'], button[type='submit']"
                );

                if( submit_btn ) {
                    submit_btn.click();
                } else {

                    var has_submit_listener = false;

                    if( element.onsubmit ) {
                        has_submit_listener = true;
                    } else if( element._scnr_engine_events ) {

                        for( var i = 0; i < element._scnr_engine_events.length; i++ ) {
                            if( element._scnr_engine_events[i][0] != 'submit' ) continue;

                            has_submit_listener = true;
                            break;
                        }

                    }

                    if( has_submit_listener ) {
                        _tokenEvents.dispatch( element, 'submit' );
                    } else {
                        element.submit();
                    }
                }
            }
        } else if( _tokenEvents.input_events[event] ) {
            if( tag_name == 'input' || tag_name == 'textarea' ) {
                element.value = options.value;
            }

            _tokenEvents.dispatch( element, event );
        } else if( event == 'click' ) {
            element.click();
        } else {
            _tokenEvents.dispatch( element, event );
        }

        return true;
    },

    fill_in_form_inputs: function( element, values ) {
        var inputs = element.querySelectorAll( 'input, textarea' );
        for( var i = 0; i < inputs.length; i++ ) {
            try {
                var input = inputs[i];
                if( input.disabled ) continue;

                var name = _tokenEvents.name_or_id( input );

                input.value = values[name] || '';
            } catch( e ) {
                console.log( e );
            }
        }

        var selects = element.querySelectorAll( 'select' );
        for( var i = 0; i < selects.length; i++ ) {
            var select = selects[i];
            if( select.disabled ) continue;

            var name  = _tokenEvents.name_or_id( input );
            var value = values[name] || '';

            for( var j = 0; j < select.options.length; j++ ) {
                var option = select.options[j];

                try {
                    if( option.getAttribute( 'value' ) == value || option.text == value ) {
                        select.selectedIndex = j;
                        return
                    }
                } catch( e ) {
                    console.log( e );
                }
            }
        }
    },

    name_or_id: function( element ) {
        return element.getAttribute( 'name' ) || element.getAttribute( 'id' );
    },

    dispatch: function( element, event ) {
        if( !_tokenDOMMonitor.is_visible( element ) ) return false;

        var e = new Event( event );

        e.view     = window;
        e.altKey   = false;
        e.ctrlKey  = false;
        e.shiftKey = false;
        e.metaKey  = false;
        e.keyCode  = 0;
        e.charCode = 'a';

        element.dispatchEvent( e );

        return true;
    }

};
