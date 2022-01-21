/*
 * Copyright 2020-2022 Tasos Laskos <tasos.laskos@gmail.com>
 *
 * This file is part of the SCNR::Engine project and is subject to
 * redistribution and commercial restrictions. Please see the SCNR::Engine
 * web site for more information on licensing and terms of use.
 */

_tokenTaintTracer.trace = function ( depth_offset ) {
    var f = arguments.callee,
        trace = [];

    depth_offset = parseInt( depth_offset ) || 3;
    for( var i = 0; i < depth_offset - 1; i++ ) {
        if( f ) f = f.caller;
    }

    var error = _tokenTaintTracer.get_error_object();
    var stackArrayOffset = depth_offset;

    var current_url = window.location.href;

    var stack_messages = error.stack.split( '\n' );
    while( stackArrayOffset <= stack_messages.length - 1 ) {
        // Skip our own functions from the trace.
        if( !_tokenTaintTracer.has_function( f ) ) {
            var frame = {
                function: {}
            };

            if( f ) {
                frame.function.source = f.toString();

                // Scripts with 'use strict' don't let us access arguments.
                try {
                    frame.function.arguments =
                        _tokenTaintTracer.sanitize_arguments( f.arguments );
                } catch( e ){ console.log( e ) }
            }

            var stack_frame = stack_messages[stackArrayOffset];

            var name_rest_splits = stack_frame.split( '@' );
            if( name_rest_splits.length > 1 ) {
                frame.function.name = name_rest_splits.shift();

                if( frame.function.name == '' ) {
                    delete frame.function.name;
                }
            }

            var url_line_col_splits = name_rest_splits.pop().split( ':' );

            // Remove the column.
            url_line_col_splits.pop();
            var url_line_splits = url_line_col_splits;

            frame.line = parseInt( url_line_splits.pop() );
            frame.url = url_line_splits.join( ':' );

            // Line numbers in the current page will be off by one after the
            // JS env has been removed, adjust accordingly.
            if( frame.url == current_url && frame.line > 0 ) {
                frame.line--;
            }

            if( frame.url != '' && frame.url != 'dummy file' ) {
                trace.push( frame );
            }
        }

        // Scripts with 'use strict' don't let us access function callers.
        if( f ) try { f = f.caller } catch(e){ f = null }
        stackArrayOffset++;
    }

    return trace;
};
